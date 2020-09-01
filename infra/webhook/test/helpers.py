import hmac, hashlib, json, copy, os

def gen_event(secret, event):
    new_event = copy.deepcopy(event)

    new_event['body'] = json.dumps(event['body'], separators = (',', ':'))

    sha1 = hmac.new(secret.encode(), new_event['body'].encode(), hashlib.sha1).hexdigest()
    new_event['headers']['x-hub-signature'] = 'sha1=%s' % sha1

    return new_event

class MockClient:
    def __init__(self):
        self.cmds = []

    def get_cmds(self):
        return self.cmds

    def reset(self):
        self.cmds = []

class MockCodebuild(MockClient):
    def start_build(self, **kwargs):
        self.cmds.append(kwargs)

class MockCodepipeline(MockClient):
    def start_pipeline_execution(self, **kwargs):
        self.cmds.append(kwargs)

def source_event(event_name):
    file_dir = os.path.dirname(__file__)
    event_path = os.path.join(file_dir, '../events/%s.json' % event_name)
    with open(event_path, 'r') as event_string:
        return json.load(event_string)

