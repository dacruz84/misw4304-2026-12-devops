# Infraestructura — Blacklist API

## Prerequisitos

- Terraform >= 1.14
- AWS CLI configurado (`aws configure`)
- Bucket S3 `terraform-blacklist-state` existente (backend de estado) — ver sección [Crear el bucket de estado](#crear-el-bucket-de-estado)
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

#### 1. Usuario IAM requerido

El usuario necesario ya existe: **`terraform-admin`** con la política **`AdministratorAccess`** adjunta.

> Si aún no lo tienes, créalo en [https://console.aws.amazon.com/iam](https://console.aws.amazon.com/iam) → **Users** → **Create user**, asígnale el nombre `terraform-admin` y adjúntale la política administrada `AdministratorAccess`.

#### 2. Generar las claves de acceso para el usuario (consola web)

1. Ingresa a [https://console.aws.amazon.com/iam](https://console.aws.amazon.com/iam)
2. En el menú izquierdo ve a **Users** y haz clic en `terraform-admin`
3. Abre la pestaña **Security credentials**
4. Baja a la sección **Access keys** y haz clic en **Create access key**
5. Selecciona el caso de uso **Command Line Interface (CLI)** → **Next**
6. (Opcional) Agrega una descripción como `terraform-cli` → **Create access key**
7. En la pantalla de confirmación verás el `Access key ID` y el `Secret access key`
   - **Copia ambos valores o descarga el CSV ahora** — la `Secret access key` no se puede recuperar después de cerrar esta pantalla

#### 3. Configurar el perfil en tu máquina (PowerShell)

Usa un perfil nombrado para no pisar otras credenciales que ya tengas (ej: de laboratorios):

```powershell
aws configure --profile blacklist
```

El comando pedirá cuatro valores:

```
AWS Access Key ID [None]:     AKIA...        # copiado o del CSV descargado
AWS Secret Access Key [None]: xxxxxxxx       # copiado o del CSV descargado
Default region name [None]:   us-east-1
Default output format [None]: json
```

Esto guarda las credenciales en `%USERPROFILE%\.aws\credentials` y la configuración en `%USERPROFILE%\.aws\config`. **Nunca subas esos archivos a git.**

#### 4. Activar el perfil para la sesión de trabajo

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

## Crear el bucket de estado

El backend de Terraform guarda el estado en S3. El bucket debe existir antes de correr cualquier `init`. Créalo una sola vez.

#### Desde la consola web

1. Ingresa a [https://s3.console.aws.amazon.com](https://s3.console.aws.amazon.com)
2. Haz clic en **Create bucket**
3. Completa los campos:
   - **Bucket name**: `terraform-blacklist-state`
   - **AWS Region**: `US East (N. Virginia) us-east-1`
4. En la sección **Bucket Versioning** selecciona **Enable**
5. Deja el resto de opciones por defecto y haz clic en **Create bucket**

> Si el bucket ya existe (lo creaste antes), omite este paso.

---

## Paso a paso

Todos los comandos se ejecutan desde la carpeta `terraform/`. Entra una sola vez antes de empezar:

```powershell
cd terraform
```

### 1. ECR

```bash
cd stacks/container_registry
terraform init  -backend-config "../../environments/da.cruz84/container_registry/backend.tfvars"
terraform plan  -var-file "../../environments/da.cruz84/container_registry/terraform.tfvars"
terraform apply -var-file "../../environments/da.cruz84/container_registry/terraform.tfvars"
cd ../..
```

### 2. RDS

```bash
cd stacks/rds
terraform init  -backend-config "../../environments/da.cruz84/rds/backend.tfvars"
terraform plan  -var-file "../../environments/da.cruz84/rds/terraform.tfvars"
terraform apply -var-file "../../environments/da.cruz84/rds/terraform.tfvars"
cd ../..
```

Anota el endpoint del output `db_address`, luego crea el parámetro SSM con la connection string:

```bash
aws ssm put-parameter --name "/blacklist/DATABASE_URL" --value "postgresql://blacklist_user:<db_password>@<db_address>:5432/blacklist_db" --type "SecureString" --region us-east-1
```

### 3. ECS

Antes de aplicar, actualiza `ssm_database_url_arn` en `environments/da.cruz84/ecs/terraform.tfvars` con el ARN real del parámetro creado arriba.

```bash
cd stacks/ecs
terraform init  -backend-config "../../environments/da.cruz84/ecs/backend.tfvars"
terraform plan  -var-file "../../environments/da.cruz84/ecs/terraform.tfvars"
terraform apply -var-file "../../environments/da.cruz84/ecs/terraform.tfvars"
cd ../..
```

### 4. Pipeline

Antes de aplicar, confirma que `ecs_task_execution_role_arn` en `environments/da.cruz84/pipeline/terraform.tfvars` coincide con el output del stack ecs:

```bash
cd stacks/ecs
terraform output task_execution_role_arn
cd ../..
```

Luego aplica:

```bash
cd stacks/pipeline
terraform init  -backend-config "../../environments/da.cruz84/pipeline/backend.tfvars"
terraform plan  -var-file "../../environments/da.cruz84/pipeline/terraform.tfvars"
terraform apply -var-file "../../environments/da.cruz84/pipeline/terraform.tfvars"
cd ../..
```

**Paso manual único:** Activa la conexión a GitHub:
1. Ve a [https://console.aws.amazon.com/codesuite/codepipeline](https://console.aws.amazon.com/codesuite/codepipeline)
2. En el menú izquierdo, al fondo, haz clic en **Settings** → **Connections**
3. Busca la conexión `blacklist-github` con estado **Pending**
4. Haz clic en ella → **Update pending connection** → autoriza con tu cuenta de GitHub

Sin esto el pipeline no dispara.

---

## Destruir

```bash
# En orden inverso
cd stacks/pipeline           ; terraform destroy -var-file "../../environments/da.cruz84/pipeline/terraform.tfvars"           ; cd ../..
cd stacks/ecs                ; terraform destroy -var-file "../../environments/da.cruz84/ecs/terraform.tfvars"                ; cd ../..
cd stacks/rds                ; terraform destroy -var-file "../../environments/da.cruz84/rds/terraform.tfvars"                ; cd ../..
cd stacks/container_registry ; terraform destroy -var-file "../../environments/da.cruz84/container_registry/terraform.tfvars" ; cd ../..
```

---

## Variables sensibles

Los `terraform.tfvars` contienen passwords y tokens — están en `.gitignore` y **no se commitean**. Los `backend.tfvars` sí se commitean (solo tienen bucket/key/region).
