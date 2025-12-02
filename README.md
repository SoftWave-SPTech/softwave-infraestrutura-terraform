# Softwave Infraestrutura Terraform

Este projeto provisiona uma infraestrutura básica na AWS utilizando Terraform, incluindo VPC, subnets públicas/privadas, NAT Gateway, EC2 frontend/backend, Security Groups e ACLs.

## Pré-requisitos
- Conta AWS com credenciais configuradas (via AWS CLI ou variáveis de ambiente)
- Terraform instalado (>= 1.2)
- Chave SSH no formato PEM

## Gerando a chave SSH PEM
Execute o comando abaixo no terminal para criar a chave:

```sh
ssh-keygen -m PEM -t rsa -b 4096 -f id_softwave.pem
```

O arquivo `id_softwave.pem` será usado para acessar as instâncias EC2.

## Passos para rodar o Terraform

1. **Clone o repositório e acesse a pasta do projeto:**
   ```sh
   cd softwave-infraestrutura-terraform
   ```

2. **Inicialize o Terraform:**
   ```sh
   terraform init
   ```

3. **Valide a configuração:**
   ```sh
   terraform validate
   ```

4. **Visualize o plano de execução:**
   ```sh
   terraform plan
   ```

5. **Aplique o plano para criar os recursos na AWS:**
   ```sh
   terraform apply
   ```
   Confirme digitando `yes` quando solicitado.

## Observações
- Certifique-se de que o arquivo `id_rsa.pem` está presente na raiz do projeto.
- Os recursos criados podem gerar custos na AWS. Remova-os com `terraform destroy` quando não forem mais necessários.
- As variáveis podem ser ajustadas em `variables.tf` conforme sua necessidade.

## Estrutura criada
- VPC customizada
- Subnets públicas e privadas
- Internet Gateway e NAT Gateway
- Instâncias EC2 frontend (públicas) e backend (privadas)
- Security Groups para frontend e backend
- ACLs para subnets
