// What are the side effects of a given drug?
MATCH (d:Drug {name: "DRUG NAME"})-[:CAUSES]->(s:SideEffect)
RETURN s.name as side_effects;



// Given a list of drugs (a patient's current regimen), find all side effects of
// the drugs (including interactions between them)
WITH ["LIST OF DRUGS..."] AS regimen
MATCH (d:Drug)-[:CAUSES]->(s:SideEffect)
WHERE d.name IN regimen

WITH COLLECT(s) AS side_effects

// This subquery finds the side effects of an interaction between any two drugs
// in the regimen
CALL {
    WITH ["LIST OF DRUGS"] AS regimen
    MATCH (d1:Drug)-[:INTERACTS]->(i:Interaction)<-[:INTERACTS]-(d2:Drug)
    MATCH (i)-[:CAUSES]->(s:SideEffect)
    WHERE d1.name IN regimen AND d2.name IN regimen
    RETURN COLLECT(s) as interaction_side_effects
}
WITH side_effects + interaction_side_effects AS side_effects
UNWIND side_effects AS side_effect
RETURN side_effect.name AS side_effects



// What are the NEW side effects of adding a new drug to a patient's existing
// regimen? First, get the drugs and side effects of patient's regimen:
CALL {
    // Given a list of drugs (a patient's current regimen), find all side effects of
    // the drugs (including interactions between them)
    WITH ["LIST OF DRUGS"] AS regimen
    MATCH (d:Drug)-[:CAUSES]->(s:SideEffect)
    WHERE d.name IN regimen

    WITH COLLECT(s) AS side_effects, regimen

    // This subquery finds the side effects of an interaction between any two drugs
    // in the regimen
    CALL {
        WITH regimen
        MATCH (d1:Drug)-[:INTERACTS]->(i:Interaction)<-[:INTERACTS]-(d2:Drug)
        MATCH (i)-[:CAUSES]->(s:SideEffect)
        WHERE d1.name IN regimen AND d2.name IN regimen
        RETURN COLLECT(s) as interaction_side_effects
    }
    RETURN side_effects + interaction_side_effects AS existing_side_effects, regimen as drug_regimen
}
// Next, look for interactions between a proposed new drug and existing drugs
WITH "DRUG NAME" as new_drug, existing_side_effects, drug_regimen
MATCH (:Drug {name: new_drug})-[:CAUSES]->(new_effects:SideEffect)
WHERE NOT new_effects IN existing_side_effects

WITH COLLECT(new_effects) AS new_effects, new_drug, existing_side_effects, drug_regimen

CALL {
    WITH new_effects, new_drug, existing_side_effects, drug_regimen
    MATCH (:Drug {name: new_drug})-[:INTERACTS]->(i:Interaction)<-[:INTERACTS]-(other_drug:Drug)
    MATCH (i)-[:CAUSES]->(s:SideEffect)
    WHERE NOT s IN existing_side_effects AND other_drug IN drug_regimen
    RETURN COLLECT(s) AS new_interaction_effects
}

WITH new_effects + new_interaction_effects AS new_side_effects
UNWIND new_side_effects AS new_side_effect
RETURN new_side_effect.name as new_side_effects



// Given a side effect, tell me which drugs (or combinations of drugs) may be 
// causing that side effect
WITH "SIDE EFFECT NAME" as side_effect
MATCH (d:Drug)-[:CAUSES]->(s:SideEffect {name: side_effect})
WITH COLLECT(d) as potential_individual_causes, side_effect
CALL {
    WITH potential_individual_causes, side_effect
    MATCH (d:Drug)-[:INTERACTS]->(i:Interaction)-[:CAUSES]->(s:SideEffect {name: side_effect})
    WHERE NOT d in potential_individual_causes
    RETURN COLLECT(d) as potential_interactive_causes
}
WITH potential_individual_causes + potential_interactive_causes AS potential_causes
UNWIND potential_causes as potential_cause
RETURN potential_cause.name;



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
    MATCH (dis:Disease {name: "DISEASE NAME"})<-[:TREATS]-(drug:Drug)
    RETURN collect(drug) as potential_drugs
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
LIMIT 1;
