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

WITH COLLECT(s.name) AS side_effects

MATCH (d1:Drug)-[:INTERACTS]->(i:Interaction)<-[:INTERACTS]-(d2:Drug)
MATCH (i:Interaction)-[:CAUSES]->(s:SideEffect)
WHERE d1.name IN regimen AND d2.name IN regimen

RETURN side_effects + COLLECT(s.name) AS side_effects;






// What are the NEW side effects of adding a new drug to a patient's existing
// regimen? First, get the drugs and side effects of patient's regimen:
CALL {
    WITH ["LIST OF DRUGS..."] AS regimen
    MATCH (d:Drug)-[:CAUSES]->(s:SideEffect)
    WHERE d.name IN regimen
    
    WITH COLLECT(d) as drug_regimen, COLLECT(s) as existing_side_effects
    
    MATCH (d1:Drug)-[:INTERACTS]->(i:Interaction)<-[:INTERACTS]-(d2:Drug)
    MATCH (i:Interaction)-[:CAUSES]->(s:SideEffect)
    WHERE d1.name IN regimen AND d2.name IN regimen
    RETURN drug_regimen + COLLECT(d1) + COLLECT(d2) as drug_regimen, existing_side_effects + COLLECT(s) as existing_side_effects
}
// Next, look for interactions between a proposed new drug and existing drugs
WITH "NEW DRUG" as new_drug
MATCH (:Drug {name: new_drug})-[:CAUSES]->(new_effects:SideEffect)
WHERE NOT new_effects IN existing_side_effects

MATCH (:Drug {name: new_drug})-[:INTERACTS]->(i:Interaction)<-[:INTERACTS]-(other_drug:Drug)
MATCH (i)-[:CAUSES]->(s:SideEffect)
WHERE NOT s IN existing_side_effects AND other_drug IN drug_regimen
RETURN COLLECT(new_effects.name) + COLLECT(s.name) AS new_side_effects







// Given a side effect, tell me which drugs (or combinations of drugs) may be 
// causing that side effect
MATCH (eff:SideEffect {name: "EFFECT NAME"})<-[:CAUSES]-(drugint)
RETURN eff, drugint

// Given a disease, find the combination of drugs that will cause the least number of side
// effects, given the drugs you’re already taking. This uses the query above
CALL {
    MATCH (dis:Disease {name: "DISEASE NAME"})<-[:TREATS]-(drug:Drug)
    RETURN collect(drug) as options
} // finish combining with query above for finding new side effects








// Gets a patient's current drug regimen, and the side effects caused by
// that regimen
CALL {
    WITH ["LIST OF DRUGS..."] AS regimen
    MATCH (d:Drug)-[:CAUSES]->(s:SideEffect)
    WHERE d.name IN regimen
    
    WITH COLLECT(d) as drug_regimen, COLLECT(s) as existing_side_effects
    
    MATCH (d1:Drug)-[:INTERACTS]->(i:Interaction)<-[:INTERACTS]-(d2:Drug)
    MATCH (i:Interaction)-[:CAUSES]->(s:SideEffect)
    WHERE d1.name IN regimen AND d2.name IN regimen
    RETURN drug_regimen + COLLECT(d1) + COLLECT(d2) as drug_regimen, existing_side_effects + COLLECT(s) as existing_side_effects
}
// Gets a list of drugs that treats a disease
CALL {
    RETURN ["LIST OF DRUGS..."] as potential_drugs
}
// Find the side effects that are caused by each new potential drug, that are
// not already in the existing side effects.
MATCH (d:Drug)-[:CAUSES]->(s:SideEffect)
WHERE d IN potential_drugs AND NOT s IN existing_side_effects

WITH d AS potential_drugs, s AS new_side_effects

// Find the side effects that are caused by each potential new drug's
// interaction with an existing drug, that are not already in the existing side
// effects or the side effects caused by the individual drug.
MATCH (d:Drug)<-[:INTERACTS]-(i:Interaction)-[:INTERACTS]->(other_drug:Drug)
MATCH (i:Interaction)-[:CAUSES]->(s:SideEffect)
WHERE d IN potential_drugs AND other_drug IN drug_regimen AND NOT s IN existing_side_effects AND NOT s in new_side_effects

// Count how many NEW side effects are introduced by a potential drug.
// Return THE drug with the least number of NEW side effects.
WITH d.name AS drug_name, COUNT(new_side_effects) + COUNT(s) as num_new_side_effects
RETURN drug_name
ORDER BY new_side_effects ASC
LIMIT 1
