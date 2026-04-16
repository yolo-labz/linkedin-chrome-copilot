// Conventional commits — enforced by lefthook (see lefthook.yml).
// Subject line ≤ 72 chars. Allowed types match CONTRIBUTING.md.
module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "type-enum": [
      2,
      "always",
      ["feat", "fix", "refactor", "chore", "docs", "test"],
    ],
    "subject-case": [0],
    "header-max-length": [2, "always", 72],
    "body-max-line-length": [1, "always", 100],
  },
};
