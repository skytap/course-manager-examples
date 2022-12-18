Metadata Stub Server

To build:

podman build -f Dockerfile -t ghcr.io/mhgoldman/course_manager_metadata_stub_server:0.1

To run:

podman run --rm -d --net cm-script-net --name gw --mount type=bind,source=/path/to/metadata/sample/on/host,target=/metadata_server/metadata.json.erb,readonly -e CONTROL_URL=control_url_goes_here metadata_server:0.1

