resource "spacelift_space" "workshop" {
  name             = "workshop"
  description      = "Space for the workshop's networking and kubernetes stacks."
  parent_space_id  = "root"
  inherit_entities = true
}
