FROM fluent/fluent-bit:5.0.9

EXPOSE 2020

ADD fluent-bit.conf /fluent-bit.conf

ENV LOG_LEVEL=debug

# No entry point so we can just shell in
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]
