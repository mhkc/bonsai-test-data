FROM alpine:3.19

WORKDIR /dataset

COPY results ./results
COPY seed ./seed

CMD ["sh"]