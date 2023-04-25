FROM python:alpine

RUN apk --no-cache add bash curl jq

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
	&& mv kubectl /usr/local/bin \
	&& chmod +x /usr/local/bin/kubectl

RUN pip install awscli --upgrade

WORKDIR /app
COPY run.sh .

ENTRYPOINT ["bash", "run.sh"]
