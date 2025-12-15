#!/usr/bin/env python3
from flask import Flask, render_template, jsonify
import os, json

app = Flask(__name__)
REPORT_DIR = os.path.expanduser(os.getenv("ACODE_REPORT_DIR", "~/.acode_dev_master/reports"))

def list_reports():
    reports = []
    if not os.path.isdir(REPORT_DIR):
        return reports
    for f in sorted(os.listdir(REPORT_DIR), reverse=True):
        if f.endswith(".json"):
            path = os.path.join(REPORT_DIR, f)
            try:
                with open(path, "r", encoding="utf-8") as fh:
                    meta = json.load(fh)
            except Exception:
                meta = {"file": f}
            meta["file"] = f
            reports.append(meta)
    return reports

@app.route("/")
def index():
    reports = list_reports()
    return render_template("index.html", reports=reports)

@app.route("/api/reports")
def api_reports():
    return jsonify(list_reports())

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
