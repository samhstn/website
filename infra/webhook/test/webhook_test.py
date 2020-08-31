import pytest
from ..function.webhook import handle_event
from .helpers import gen_event, MockCodebuild, source_event

secret = 'S8UVDlEXAMPLE'

@pytest.fixture
def events():
    events_dict = {}
    event_names = ('sample_ping', 'raw_ping', 'sample_push', 'raw_push')

    for e in event_names:
        events_dict[e] = source_event(e) 

    return events_dict

def test_gen_event(events):
    expected_event = {
      'sample': True,
      'headers': {
        'x-github-event': 'ping',
        'x-hub-signature': 'sha1=65c39e67c45a90243c1d8c97efd002cb46298f3d'
      },
      'body': 'cGF5bG9hZCUzRCU3QiUyMnplbiUyMiUzQSUyMlByYWN0aWNhbGl0eSUyQmJlYXRzJTJCcHVyaXR5LiUyMiU3RA=='
    }

    assert gen_event(secret, events['sample_ping']) == expected_event

def test_ping_event_with_correct_secret(events):
    for e in ('sample_ping', 'raw_ping'):
        mock_codebuild = MockCodebuild()

        event = gen_event(secret, events[e])

        res = handle_event(event, secret, mock_codebuild, push='push', delete='delete')

        assert res == {'statusCode': 200, 'body': 'OK'}
        assert mock_codebuild.get_builds() == []

def test_push_event_with_correct_secret(events):
    for e in ('sample_push', 'raw_push'):
        mock_codebuild = MockCodebuild()

        event = gen_event(secret, events[e])

        res = handle_event(event, secret, mock_codebuild, push='push', delete='delete')

        assert res == {'statusCode': 200, 'body': 'Starting build for branch: dci#84'}
        assert mock_codebuild.get_builds() == [{
            'projectName': 'push',
            'sourceVersion': 'dci#84',
            'artifactsOverride': {'type': 'NO_ARTIFACTS'},
            'environmentVariableOverride': [{
                'name': 'ISSUE_NUMBER',
                'type': 'PLAINTEXT',
                'value': '84'
            }]
        }]

def test_events_with_signature_mismatch(events):
    for e in ('sample_ping', 'raw_ping', 'sample_push', 'raw_push'):
        mock_codebuild = MockCodebuild()

        event = gen_event(secret, events[e])

        res = handle_event(event, 'WRONGSECRET', mock_codebuild, push='push', delete='delete')

        assert res == {'statusCode': 403, 'body': 'x-hub-signature mismatch'}
        assert mock_codebuild.get_builds() == []
