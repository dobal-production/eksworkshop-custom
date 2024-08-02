## Docker 환경정보 보기
```shell
docker info
```
```yaml
 ...
 Kernel Version: 6.1.92-99.174.amzn2023.x86_64
 Operating System: Amazon Linux 2023.5.20240708
 OSType: linux
 Architecture: x86_64
 CPUs: 2
 Total Memory: 7.59GiB
 Name: ip-10-1-0-59.ap-northeast-2.compute.internal
 ID: 2ac6b2c6-c38f-42a2-961f-7527fa76d408
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 Experimental: false
 Insecure Registries:
```
## Container Image 만들기
### Dockerfile
```shell
cd ~/environment

cat << EOF > Dockerfile
FROM nginx:latest
RUN  echo '<h1> Dobal's Web Page </h1>'  >> index.html
RUN cp /index.html /usr/share/nginx/html
EOF
```
### Docker Image Build
```shell
docker build -t test-image .
```
```shell
docker images
```
```shell
docker image inspect test-image
```
### Docker Run
```shell
docker run -p 8080:80 --name test-nginx test-image
```
```shell
docker ps
```
```shell
docker logs -f test-nginx
```
```shell
docker inspect [container_id] --format "{{.LogPath}}"
```
```shell
sudo cat [log_path]
```
### Remove Container & Image
* 현재 실행중인 컨테이너는 삭제할 수 없음
* 이미지가 사용된 컨테이너(실행 상태와 상관 없음)가 있으면 이미지는 삭제할 수 없음
```shell
docker stop test-ngix
```
```shell
docker rmi test-image
```
```shell
docker rm test-nginx
```
```shell
docker rmi test-image
```

## Amazon ECR Repository
### Create Amazon ECR Repository
```shell
aws ecr create-repository \
--repository-name demo-flask-backend \
--image-scanning-configuration scanOnPush=true \
--region ${AWS_REGION}
```
### Login to Amazon ECR Repository
```shell
export ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```
### Build docker image
```shell
cd ~/environment
git clone https://github.com/joozero/amazon-eks-flask.git
```
```shell
cd amazon-eks-flask
docker build -t demo-flask-backend .
```
```shell
docker images
docker tag demo-flask-backend:latest $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/demo-flask-backend:latest
docker images
```
```shell
docker push $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/demo-flask-backend:latest
```
### Delete images and run
```shell
docker rmi demo-flask-backend
docker rmi $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/demo-flask-backend
```
```shell
docker run -p 8080:8080 --name demo-flask $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/demo-flask-backend:latest
```
## Example: Bedrock RAG Stock
```shell
git clone https://github.com/nguyendinhthi0705/bedrock-rag-stock.git
```
```shell
cd ~/environment/bedrock-rag-stock
cat << EOF > Dockerfile
FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get upgrade -y

COPY requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

COPY 1_stock_qna/ 1_stock_qna/ 
COPY 2_stock_query/ 2_stock_query/
COPY 3_stock_tools/ 3_stock_tools/
COPY 4_stock_analysis/ 4_stock_analysis/
COPY images/ images/

COPY *.py .
COPY Artificial-Intelligence-Stocks.jpg .

EXPOSE 80

HEALTHCHECK CMD curl --fail http://localhost/_stcore/health || exit 1

ENTRYPOINT [ "streamlit", "run", "main.py", \
             "--logger.level", "info", \
             "--browser.gatherUsageStats", "false", \
             "--browser.serverAddress", "0.0.0.0", \
             "--server.enableCORS", "false", \
             "--server.enableXsrfProtection", "false", \
             "--server.port", "80"]
EOF
```
```shell
docker build -t rag-stock-image .
```
```shell
docker run -p 8080:80 --name stock-analysis rag-stock-image
```