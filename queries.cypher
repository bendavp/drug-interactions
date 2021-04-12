// Import drug-disease CSV into Neo4J
LOAD CSV WITH HEADERS FROM 'file:///drug_disease.csv' AS row
MERGE (drug:Drug {name: row.`Drug Name`, id: row.`Drug ID`})
MERGE (disease:Disease {name: row.`Disease Name`, id: row.`Disease ID`})
MERGE (drug)-[t:TREATS]->(disease);

// Import drug-drug-side_effect CSV into Neo4J
LOAD CSV WITH HEADERS FROM 'file:///drug_interaction_side_effects.csv' AS row
MERGE (drug1:Drug {name: row.`Drug 1 Name`, id: row.`Drug 1 ID`})
MERGE (drug2:Drug {name: row.`Drug 2 Name`, id: row.`Drug 2 ID`})
MERGE (i:Interaction {drug1_name: row.`Drug 1 Name`, drug2_name: row.`Drug 2 Name`})
MERGE (s:SideEffect {name: row.`Side Effect Name`, id: row.`Side Effect ID`})
MERGE (drug1)-[:INTERACTS]->(i)<-[:INTERACTS]-(drug2)
MERGE (i)-[:CAUSES]->(s);

// Import drug-disease CSV into Neo4J
LOAD CSV WITH HEADERS FROM 'file:///drug_side_effects.csv' AS row
MERGE (drug:Drug {name: row.`Drug Name`, id: row.`Drug ID`})
MERGE (s:SideEffect {name: row.`Side Effect Name`, id: row.`Side Effect ID`})
MERGE (drug)-[:CAUSES]->(s);

// What are the side effects of a given drug?
MATCH (d:Drug {name: "DRUG NAME"})-[:CAUSES]->(s:SideEffect)
RETURN s.name as side_effects

// Given a list of drugs (a patient's current regimen), find all side effects of
// the drugs (including interactions between them)
WITH ["LIST OF DRUGS..."] AS regimen
MATCH (d:Drug)-[:CAUSES]->(s:SideEffect)
WHERE d.name IN regimen
RETURN s.name as side_effects
UNION
MATCH (d1:Drug)-[:INTERACTS]->(i:Interaction)<-[:INTERACTS]-(d2:Drug)
MATCH (i:Interaction)-[:CAUSES]->(s:SideEffect)
WHERE d1.name IN regimen AND d2.name IN regimen
RETURN s.name as side_effects

// What are the NEW side effects of adding a new drug to a patient's existing
// regimen? First, get the drugs and side effects of patient's regimen:
WITH ["LIST OF DRUGS..."] AS regimen
CALL {
    MATCH (d:Drug)-[:CAUSES]->(s:SideEffect)
    WHERE d.name IN regimen
    RETURN d, s
    UNION
    MATCH (d1:Drug)-[:INTERACTS]->(i:Interaction)<-[:INTERACTS]-(d2:Drug)
    MATCH (i:Interaction)-[:CAUSES]->(s:SideEffect)
    WHERE d1.name IN regimen AND d2.name IN regimen
    RETURN d1, d2, s
}
// Next, look for interactions between a proposed new drug and existing drugs