FROM ubuntu

# install system deps
RUN apt-get update && apt-get install -y bash curl jq unzip

# install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
	&& mv kubectl /usr/local/bin \
	&& chmod +x /usr/local/bin/kubectl

# install aws-cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm -Rf ./aws awscliv2.zip

WORKDIR /app
COPY run.sh .

ENTRYPOINT ["bash", "run.sh"]
