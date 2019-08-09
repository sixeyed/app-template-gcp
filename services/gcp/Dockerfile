FROM google/cloud-sdk:257.0.0-alpine

ENTRYPOINT ["/bin/sh"]
CMD ["/setup.sh"]

RUN apk --no-cache update && \
    apk --no-cache add jq

COPY setup.sh /