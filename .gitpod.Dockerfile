FROM gitpod/workspace-full

ENV RETRIGGER=1

ENV BUILDKIT_VERSION=0.9.3
ENV BUILDKIT_FILENAME=buildkit-v${BUILDKIT_VERSION}.linux-amd64.tar.gz

# Install custom tools, runtime, etc.
RUN sudo su -c "cd /usr; curl -L https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/${BUILDKIT_FILENAME} | tar xvz" && \
sudo su -c "cd /usr/bin; curl -o yq -L https://github.com/mikefarah/yq/releases/download/v4.22.1/yq_linux_amd64 && chmod +x yq"

