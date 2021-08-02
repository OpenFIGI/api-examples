#lang racket

;
; Based on example taken from https://www.openfigi.com/api
;
;    curl 'https://api.openfigi.com/v3/mapping' \
;        --request POST \
;        --header 'Content-Type: application/json' \
;        --data '[{"idType":"ID_WERTPAPIER","idValue":"851399","exchCode":"US"}]'

(require net/http-easy)

(define figi-api-url "https://api.openfigi.com/v3/mapping")

(define figi-response
  (response-json
   (post figi-api-url
         #:headers (hasheq 'content-type "application/json")
         #:json (list
                 (hasheq 'idType "ID_WERTPAPIER"
                         'idValue "851399"
                         'exchCode "US")))))

figi-response
