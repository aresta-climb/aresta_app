## ADDED Requirements

### Requirement: O parser de áreas deve usar a nomenclatura da v4
The system SHALL parse PontoDeInteresse geometries using the v4 vocabulary: circulo, retangulo, poligono, quadrado.

#### Scenario: Parsing circulo
- **WHEN** point type is circulo
- **THEN** it generates a circular polygon based on its x, y, and raio

#### Scenario: Parsing retangulo
- **WHEN** point type is retangulo
- **THEN** it generates a rectangular polygon with rotation

#### Scenario: Parsing poligono
- **WHEN** point type is poligono
- **THEN** it generates a freeform polygon

#### Scenario: Parsing quadrado
- **WHEN** point type is quadrado
- **THEN** it generates a square polygon based on x, y and lado without rotation
