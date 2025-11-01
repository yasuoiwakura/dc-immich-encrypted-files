FROM alpine

RUN apk add --no-cache netcat-openbsd bash

COPY auth.sh /auth.sh
RUN chmod +x /auth.sh

# Festes ENTRYPOINT – dieser Container führt IMMER das Skript aus
ENTRYPOINT ["/auth.sh"]
