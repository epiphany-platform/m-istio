FROM alpine:latest

ENV M_WORKDIR "/workdir"
ENV M_RESOURCES "/resources"
ENV M_SHARED "/shared"

ARG YQ_VERSION=3.3.4
ARG KUBECTL_VERSION=1.18.8
ARG ISTIOCTL_VERSION=1.8.1
ENV AWSCLI_VERSION 1.18.196

WORKDIR /workdir
ENTRYPOINT ["make"]

#install make, YQ, kubectl and istioctl 
RUN apk add --update --no-cache make=4.3-r0 tar python3 py-pip &&\

    wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq &&\

    wget https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -O /usr/bin/kubectl &&\
    chmod +x /usr/bin/kubectl &&\

    wget https://github.com/istio/istio/releases/download/${ISTIOCTL_VERSION}/istioctl-${ISTIOCTL_VERSION}-linux-amd64.tar.gz -O istioctl.tar.gz &&\
    tar -xzvf istioctl.tar.gz -C /usr/bin &&\
    rm istioctl.tar.gz &&\
    chmod +x /usr/bin/istioctl &&\

    pip install awscli==${AWSCLI_VERSION}

ARG ARG_M_VERSION="unknown"
ENV M_VERSION=$ARG_M_VERSION

COPY resources/ /resources
COPY workdir /workdir

ARG ARG_HOST_UID=1000
ARG ARG_HOST_GID=1000
RUN chown -R $ARG_HOST_UID:$ARG_HOST_GID \
    $M_WORKDIR \
    $M_RESOURCES

USER $ARG_HOST_UID:$ARG_HOST_GID
# Set HOME to directory with necessary permissions for current user
ENV HOME=$M_WORKDIR
