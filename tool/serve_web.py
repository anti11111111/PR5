"""Serves the built web app and returns index.html for client-side routes."""

from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "build", "web")


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.path.abspath(ROOT), **kwargs)

    def do_GET(self):
        path = self.translate_path(self.path.split("?", 1)[0])
        if not os.path.isfile(path):
            self.path = "/index.html"
        return super().do_GET()


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", 5560), Handler)
    print("http://127.0.0.1:5560", flush=True)
    server.serve_forever()
