# This simple script compiles the typescript files, opens a local webserver, and runs the client.
# NOTE: user must strart data_adapter.q manually, as I was unable to automate this in a sh script.
tsc
sass src/style.scss install/style.css
open http://localhost:8080
http-server -p 8080