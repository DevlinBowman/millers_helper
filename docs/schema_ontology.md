
# Ontology
## Universes

Kind          Meaning
_____________________
value        symbolic enumerations
field        object attributes
shape        structural membership/order

value universe
board.grade → { CA, CC, HC }

field universe
board → { base_h, base_w, grade }

shape universe
board → ordering of fields

# Namespaces

Domain type         Example
object domain       board, order
value domain        board.grade, board.species


# Identity

Every schema entity has a name inside its domain.

# attrubute

Attributes describe properties of the entity.

rank
description
multiplier
unit

value(board.grade, CA)
{
    code = "CA",
    rank = 3,
    description = "Clear All Heart"
}

