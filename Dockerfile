FROM alpine:3.19

WORKDIR /dataset

COPY samples ./samples
COPY seed ./seed

CMD ["sh"]