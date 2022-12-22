from flask import Flask
from flask import request, jsonify

app = Flask(__name__)

@app.route('/',methods=['POST'])
def root():
   if request.method=='POST':
      print(request.json,flush=True)
      return jsonify({'status':'OK'}), 200
   else:
      return "Not allowed",405
