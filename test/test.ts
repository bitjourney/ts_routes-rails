import * as Routes from "./build/routes";

let i = 0;
let notOk = 0;

function assertEqual(actual: string, expected: string) {
  if (actual === expected) {
    console.log("ok - %d # %s", ++i, actual);
  } else {
    console.log("not ok - %d # actual: %s, expected: %s", ++i, actual, expected);
    notOk++;
  }
}

assertEqual(Routes.entriesPath(), "/entries");

assertEqual(Routes.entriesPath({ page: 1, per: 20 }), "/entries?page=1&per=20");
assertEqual(Routes.entryPath(42, { format: "json" }), "/entries/42.json");
assertEqual(Routes.entryPath(42, { anchor: "foo bar baz", from: "twitter" }), "/entries/42?from=twitter#foo%20bar%20baz");

assertEqual(Routes.photosPath(["2017", "06", "15"], { id: 42 }), "/photos/2017/06/15/42");

console.assert(notOk === 0, "all tests passes");
