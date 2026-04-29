# Infraestructura — Blacklist API

## Prerequisitos

- Terraform >= 1.14
- AWS CLI configurado (`aws configure`)
- Bucket S3 `terraform-blacklist-state` existente (backend de estado)
- Docker instalado (solo para builds locales)

### Verificar Terraform

```bash
terraform -version
```

Si no está instalado o la versión es menor a 1.14:

```bash
# Windows (winget)
winget install HashiCorp.Terraform

# macOS (Homebrew)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Actualizar versión existente
# Windows:
winget upgrade HashiCorp.Terraform
# macOS:
brew upgrade hashicorp/tap/terraform
```

### Verificar AWS CLI

```bash
aws --version
```

Si no está instalado o está desactualizado:

```bash
# Windows — descarga el instalador MSI:
# https://awscli.amazonaws.com/AWSCLIV2.msi
# O con winget:
winget install Amazon.AWSCLI

# macOS:
brew install awscli

# Actualizar versión existente
# Windows:
winget upgrade Amazon.AWSCLI
# macOS:
brew upgrade awscli
```

### Configurar credenciales AWS en Windows

#### 1. Obtener las claves de acceso en la consola de AWS

1. Ingresa a [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Haz clic en tu nombre de usuario (esquina superior derecha) → **Security credentials**
3. Baja a la sección **Access keys** → **Create access key**
4. Selecciona el caso de uso **Command Line Interface (CLI)** → Next
5. Descarga el archivo CSV — la `Secret Access Key` solo se muestra en este momento, guárdala

#### 2. Configurar el perfil en tu máquina (PowerShell)

Usa un perfil nombrado para no pisar otras credenciales que ya tengas (ej: de laboratorios):

```powershell
aws configure --profile blacklist
```

El comando pedirá cuatro valores:

```
AWS Access Key ID [None]:     AKIA...        # del CSV descargado
AWS Secret Access Key [None]: xxxxxxxx       # del CSV descargado
Default region name [None]:   us-east-1
Default output format [None]: json
```

Esto guarda las credenciales en `%USERPROFILE%\.aws\credentials` y la configuración en `%USERPROFILE%\.aws\config`. **Nunca subas esos archivos a git.**

#### 3. Activar el perfil para la sesión de trabajo

```powershell
$env:AWS_PROFILE = "blacklist"
```

Ejecuta esto una vez por sesión de PowerShell antes de correr cualquier comando de Terraform o AWS CLI. Para verificar que funciona:

```powershell
aws sts get-caller-identity
```

Debe devolver tu `Account`, `UserId` y `Arn`. Si ves un error de credenciales, repite el paso 2.

---

## Stacks y qué provisiona cada uno

| Stack | Qué crea |
|---|---|
| `container_registry` | Repositorio ECR `n2d/blacklist` |
| `rds` | Instancia RDS PostgreSQL `db.t3.micro`, base de datos `blacklist_db`, usuario `blacklist_user` |
| `ecs` | Cluster ECS, Task Definition Fargate, Service, IAM roles, Security Group, CloudWatch log group |
| `pipeline` | CodeBuild project, CodePipeline (Source → Build → Deploy), S3 artifacts, conexión GitHub |

---

## Paso a paso

Todos los comandos se ejecutan desde dentro del stack correspondiente.

### 1. ECR

```bash
cd stacks/container_registry
terraform init -backend-config=../../environments/da.cruz84/container_registry/backend.tfvars
terraform apply -var-file=../../environments/da.cruz84/container_registry/terraform.tfvars
```

### 2. RDS

```bash
cd stacks/rds
terraform init -backend-config=../../environments/da.cruz84/rds/backend.tfvars
terraform apply -var-file=../../environments/da.cruz84/rds/terraform.tfvars
```

Anota el endpoint del output `db_address`, luego crea el parámetro SSM con la connection string:

```bash
aws ssm put-parameter \
  --name "/blacklist/DATABASE_URL" \
  --value "postgresql://blacklist_user:B1ackl!st9xP@<db_address>:5432/blacklist_db" \
  --type "SecureString" \
  --region us-east-1
```

### 3. ECS

Antes de aplicar, actualiza `ssm_database_url_arn` en `environments/da.cruz84/ecs/terraform.tfvars` con el ARN real del parámetro creado arriba.

```bash
cd stacks/ecs
terraform init -backend-config=../../environments/da.cruz84/ecs/backend.tfvars
terraform apply -var-file=../../environments/da.cruz84/ecs/terraform.tfvars
```

### 4. Pipeline

Antes de aplicar, confirma que `ecs_task_execution_role_arn` en `environments/da.cruz84/pipeline/terraform.tfvars` coincide con el output del stack ecs:

```bash
# Desde stacks/ecs:
terraform output task_execution_role_arn
```

Luego aplica:

```bash
cd stacks/pipeline
terraform init -backend-config=../../environments/da.cruz84/pipeline/backend.tfvars
terraform apply -var-file=../../environments/da.cruz84/pipeline/terraform.tfvars
```

**Paso manual único:** Ve a AWS Console → Developer Tools → Connections → activa la conexión `blacklist-github` para autorizar el acceso a GitHub. Sin esto el pipeline no dispara.

---

## Destruir

```bash
# En orden inverso
cd stacks/pipeline && terraform destroy -var-file=../../environments/da.cruz84/pipeline/terraform.tfvars
cd stacks/ecs     && terraform destroy -var-file=../../environments/da.cruz84/ecs/terraform.tfvars
cd stacks/rds     && terraform destroy -var-file=../../environments/da.cruz84/rds/terraform.tfvars
cd stacks/container_registry && terraform destroy -var-file=../../environments/da.cruz84/container_registry/terraform.tfvars
```

---

## Variables sensibles

Los `terraform.tfvars` contienen passwords y tokens — están en `.gitignore` y **no se commitean**. Los `backend.tfvars` sí se commitean (solo tienen bucket/key/region).
