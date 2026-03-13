FROM legionio/legion

COPY . /usr/src/app/lex-vault

WORKDIR /usr/src/app/lex-vault
RUN bundle install
