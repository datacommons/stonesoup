workflow "New workflow" {
  on = "push"
  resolves = [
    "GitHub Action for Slack",
    "maddox/actions/ssh@6fc6694b013badc932fb2a6ec6edfa4e629254cf",
  ]
}

action "Filters for GitHub Actions" {
  uses = "actions/bin/filter@712ea355b0921dd7aea27d81e247c48d0db24ee4"
  args = "branch test"
}

action "GitHub Action for Slack" {
  uses = "Ilshidur/action-slack@1ee0e72f5aea6d97f26d4a67da8f4bc5774b6cc7"
  needs = ["Filters for GitHub Actions"]
  secrets = ["SLACK_WEBHOOK"]
  args = "pushed to test"
}

action "maddox/actions/ssh@6fc6694b013badc932fb2a6ec6edfa4e629254cf" {
  uses = "maddox/actions/ssh@6fc6694b013badc932fb2a6ec6edfa4e629254cf"
  needs = ["Filters for GitHub Actions"]
  secrets = ["PRIVATE_KEY", "PUBLIC_KEY", "HOST", "USER"]
  args = "./deploy.sh staging test"
}
