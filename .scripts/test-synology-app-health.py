"""Regression checks for healthy HTTP responses containing application warnings."""
import importlib.util
import io
import pathlib
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('app_health', pathlib.Path(__file__).with_name('synology-app-health.py'))
health = importlib.util.module_from_spec(spec)
spec.loader.exec_module(health)


class Opener:
    def __init__(self, body):
        self.body = body

    def open(self, request, timeout):
        return io.BytesIO(self.body)


class AppHealthTests(unittest.TestCase):
    def test_http_success_does_not_hide_warning(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = pathlib.Path(tmp) / 'config.xml'
            config.write_text('<Config><ApiKey>fixture-secret</ApiKey></Config>')
            status, message = health.check_service('prowlarr', 'http://localhost/health', config,
                Opener(b'[{"type":"warning","message":"fixture-secret"}]'))
            self.assertEqual(status, 1)
            self.assertEqual(message, 'APP prowlarr warnings=1 errors=0')
            self.assertNotIn('fixture-secret', message)

    def test_clean_response(self):
        self.assertEqual(health.classify([]), (0, 0))

    def test_bad_response_cannot_pass(self):
        for value in ({}, [None], [{'type':'unexpected'}]):
            with self.assertRaises(ValueError):
                health.classify(value)

    def test_missing_credentials_report_unavailable(self):
        status, message = health.check_service('sonarr', 'http://localhost', '/not/a/config.xml', Opener(b'[]'))
        self.assertEqual((status, message), (2, 'APP sonarr status=unavailable'))

    def test_redirect_rejected(self):
        self.assertIsNone(health.NoRedirect().redirect_request(None, None, 302, '', {}, 'http://elsewhere'))


if __name__ == '__main__':
    unittest.main()
