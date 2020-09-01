import pytest
from ..function.webhook import handle_event
from .helpers import gen_event, MockCodebuild, MockCodepipeline, source_event

secret = 'S8UVDlEXAMPLE'

@pytest.fixture
def events():
    events_dict = {}
    event_names = ('sample_ping', 'raw_ping', 'sample_push', 'raw_push')

    for e in event_names:
        events_dict[e] = source_event(e) 

    return events_dict

@pytest.fixture
def client():
    codebuild, codepipeline = MockCodebuild(), MockCodepipeline()

    return {'codebuild': codebuild, 'codepipeline': codepipeline}

@pytest.fixture
def environ():
    return {'github_master_branch': 'master', 'push': 'push', 'delete': 'delete'}

def test_gen_event(events):
    expected_event = {
      'sample': True,
      'headers': {
        'x-github-event': 'ping',
        'x-hub-signature': 'sha1=bd02e793115c17f9ce51941d5e29a0d1ffb9c6d3'
      },
      'body': '{"zen":"Practicality+beats+purity."}'
    }

    assert gen_event(secret, events['sample_ping']) == expected_event

def test_ping_event_with_correct_secret(events, client):
    for e in ('sample_ping', 'raw_ping'):
        event = gen_event(secret, events[e])

        res = handle_event(event, secret, client, environ)

        assert res == {'statusCode': 200, 'body': 'OK'}
        assert client['codebuild'].get_cmds() == []

def test_push_event_with_correct_secret(events, client, environ):
    for e in ('sample_push', 'raw_push'):
        event = gen_event(secret, events[e])

        res = handle_event(event, secret, client, environ)

        assert res == {'statusCode': 200, 'body': 'Starting build for branch: dci#84'}
        assert client['codebuild'].get_cmds() == [{
            'projectName': 'push',
            'sourceVersion': 'dci#84',
            'artifactsOverride': {'type': 'NO_ARTIFACTS'},
            'environmentVariablesOverride': [{
                'name': 'ISSUE_NUMBER',
                'type': 'PLAINTEXT',
                'value': '84'
            }]
        }]
        client['codebuild'].reset()

def test_events_with_signature_mismatch(events, client, environ):
    for e in ('sample_ping', 'raw_ping', 'sample_push', 'raw_push'):
        event = gen_event(secret, events[e])

        res = handle_event(event, 'WRONGSECRET', client, environ)

        assert res == {'statusCode': 403, 'body': 'x-hub-signature mismatch'}
        assert client['codebuild'].get_cmds() == []
