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
        url = f"{api}{self.request["path"]}"
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
                    self.fail(f"Expected result must be a dict, not {type(expected)}: {expected}")
                for key, expected_value in expected.items():
                    if match_type == "str_equals":
                        self.test_str_equals(f"result['{i + 1}']['{key}']", expected_value, response_data[i][key])
                    elif match_type == "regexp_full":
                        self.test_regexp_full(f"result['{i + 1}']['{key}']", expected_value, response_data[i][key])
                    else:
                        self.fail(f"Unsupported comparison {match_type}")
        self.passed() 

    def test_is_type(self, obj, expected_type):
        if type(obj) is not expected_type:
            self.fail(f" {type(obj)} but {expected_type} was expected.")

    def test_regexp_full(self, what, regexp, got):
        """Compare provided string with a regular expression. The expression must match the full string.
        """
        if not re.fullmatch(regexp, got):
            print(f"pattern: {regexp}  string: {got}")
            self.fail(f"{what}: {got} does not match regular expression '{regexp}'")

    def test_equals(self, what, expected, got):
        if got != expected:
            self.fail(f"{what}: {got} but {expected} was expected.")

    def test_str_equals(self, what, expected, got):
        if str(got) != str(expected):
            self.fail(f"{what}: {got} but {expected} was expected.")

    def print_traceback(self, color):
        for line in traceback.format_stack():
            print(colored(line.strip(), color))

    def fail(self, message):
        text = f"ERROR: Test '{self.name}' failed.\n{message}"
        print(colored(text, 'red'))
        self.print_traceback('red')
        sys.exit(1)
    
    def passed(self):
        text = f"PASSED: {self.name}"
        print(colored(text, 'green'))
 

parser = argparse.ArgumentParser(description="Run test queries against OpenRailwayMap API and compare results.")
parser.add_argument("-a", "--api", type=str, help="API endpoint", default="http://127.0.0.1:5000")
parser.add_argument("-t", "--tests", type=argparse.FileType("r"), help="Test definitions (YAML)")
args = parser.parse_args()

cases = yaml.safe_load(args.tests)
cases = [TestCase(**e) for e in cases]
for case in cases:
    case.run(args.api)
