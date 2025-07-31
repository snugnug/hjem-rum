import argparse
from dataclasses import dataclass
import sys

from ast_grep_py import Edit, SgNode, SgRoot
from whenever import Date, DateDelta


def extract_components_from_node(node: SgNode):
    return (
        node.get_match("FUNCTION"),
        node.get_match("OLD_PATH"),
        node.get_match("NEW_PATH"),
        node.get_match("DATE"),
    )


# https://stackoverflow.com/a/71035314
@dataclass
class DeprecateArgs:
    filename: str
    cutoff_duration: str


parser = argparse.ArgumentParser(
    prog="hjr-deprecate",
    description="Deprecate renamed and removed options if needed.",
)

cutoff_duration: DateDelta

_ = parser.add_argument("filename", type=str)
_ = parser.add_argument("-d", "--cutoff-duration", type=str)


args = DeprecateArgs(**vars(parser.parse_args(sys.argv[1:] or ["--help"])))
try:
    cutoff_duration = DateDelta.parse_common_iso(args.cutoff_duration)
except TypeError:
    _ = sys.stderr.write("cutoff-duration is not a valid ISO-8601 duration")
    exit(1)

today = Date.today_in_system_tz()

cutoff_date = today - cutoff_duration
new_deprecation_date = today + cutoff_duration

edits: list[Edit] = []
with open(args.filename) as file:
    root = SgRoot(file.read(), "nix")
    node = root.root()
    renamed_nodes = node.find_all(
        {
            "rule": {"pattern": "($FUNCTION $OLD_PATH $NEW_PATH $DATE)"},
            "constraints": {
                "FUNCTION": {
                    "regex": "^mkRenamedOptionModuleUntil$",
                }
            },
        }
    )
    removed_nodes = node.find_all(
        {
            "rule": {"pattern": "($FUNCTION $OLD_PATH $NEW_PATH $DATE)"},
            "constraints": {
                "FUNCTION": {
                    "regex": "^mkRemovedOptionModuleUntil$",
                }
            },
        }
    )

    for renamed_node in renamed_nodes:
        function_node, old_path_node, new_path_node, date_node = (
            extract_components_from_node(renamed_node)
        )

        date_text = renamed_node.get_match("DATE").text().strip('"')
        date = Date.parse_common_iso(date_text)

        if date <= cutoff_date:
            function_edit = function_node.replace("mkRemovedOptionModuleUntil")
            date_iso = new_deprecation_date.format_common_iso()
            date_edit = date_node.replace(date_iso)
            edits.append(date_edit)
            edits.append(function_edit)

    for removed_node in removed_nodes:
        function_node, old_path_node, new_path_node, date_node = (
            extract_components_from_node(removed_node)
        )

        date_text = removed_node.get_match("DATE").text().strip('"')
        date = Date.parse_common_iso(date_text)

        if date <= cutoff_date:
            edits.append(removed_node.replace(""))

if edits:
    _ = sys.stdout.write(root.root().commit_edits(edits))
