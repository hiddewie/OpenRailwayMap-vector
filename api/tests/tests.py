import argparse
import re
import requests
import sys
from termcolor import colored
import traceback
import yaml


class TestCase():

    def __init__(self, **kwargs):
        self.name = kwargs["name"]
        self.request = kwargs["request"]
        self.response = kwargs["response"]

    def run(self, api):
        url = "{}{}".format(api, self.request["path"])
        r = requests.get(url, params=self.request.get("params"))
        self.test_equals("status code", r.status_code, self.response.get("status", 200))
        response_data = r.json()
        # Test result count
        expected_count = self.response.get("count")
        if expected_count is not None:
            self.test_equals("result count", len(response_data), expected_count)
        # Test result names
        expected_results = self.response.get("entries")
        if expected_results is not None:
            self.test_equals("result_count", len(expected_results), len(response_data))
            match_type = self.response.get("match", "str_equals")
            for i in range(0, len(expected_results)):
                expected = expected_results[i]
                got = response_data[i]
                if type(expected) is not dict:
                    self.fail("Expected result must be a dict, not {}: {}".format(type(expected), expected))
                for key, expected_value in expected.items():
                    if match_type == "str_equals":
                        self.test_str_equals("result['{}']['{}']".format(i + 1, key), expected_value, response_data[i][key])
                    elif match_type == "regexp_full":
                        self.test_regexp_full("result['{}']['{}']".format(i + 1, key), expected_value, response_data[i][key])
                    else:
                        self.fail("Unsupported comparison {}".format(match_type))
        self.passed() 

    def test_is_type(self, obj, expected_type):
        if type(obj) is not expected_type:
            self.fail(" {} but {} was expected.".format(status))

    def test_regexp_full(self, what, regexp, got):
        """Compare provided string with a regular expression. The expression must match the full string.
        """
        if not re.fullmatch(regexp, got):
            print("pattern: {}  string: {}".format(regexp, got))
            self.fail("{}: {} does not match regular expression '{}'".format(what, got, regexp))

    def test_equals(self, what, expected, got):
        if got != expected:
            self.fail("{}: {} but {} was expected.".format(what, got, expected))

    def test_str_equals(self, what, expected, got):
        if str(got) != str(expected):
            self.fail("{}: {} but {} was expected.".format(what, got, expected))

    def print_traceback(self, color):
        for line in traceback.format_stack():
            print(colored(line.strip(), color))

    def fail(self, message):
        text = "ERROR: Test '{}' failed.\n{}".format(self.name, message)
        print(colored(text, 'red'))
        self.print_traceback('red')
        sys.exit(1)
    
    def passed(self):
        text = "PASSED: {}".format(self.name)
        print(colored(text, 'green'))
 

parser = argparse.ArgumentParser(description="Run test queries against OpenRailwayMap API and compare results.")
parser.add_argument("-a", "--api", type=str, help="API endpoint", default="http://127.0.0.1:5000")
parser.add_argument("-t", "--tests", type=argparse.FileType("r"), help="Test definitions (YAML)")
args = parser.parse_args()

cases = yaml.safe_load(args.tests)
cases = [TestCase(**e) for e in cases]
for case in cases:
    case.run(args.api)
