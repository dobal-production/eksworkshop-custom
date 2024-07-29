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