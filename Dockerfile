FROM legionio/legion

COPY . /usr/src/app/lex-cortex

WORKDIR /usr/src/app/lex-cortex
RUN bundle install
