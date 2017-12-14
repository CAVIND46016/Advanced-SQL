--    Implement the HITS authority-hubs algorithm. during class.
--    The input data is given in a relation Graph(source INTEGER, target INTEGER) which represent the graph on which the HITS Algorithm   --    operates. So each node in this graph will receive an authority and a hub score.
--    For more information about the HITS algorithm consult
--    https://en.wikipedia.org/wiki/HITS_algorithm
--    https://www.youtube.com/watch?v=jr3YGgfDY_E
--    An important detail of the HITS algorithm concerns the normalization of the authority vector (analogously, the hub vector). This --    vector needs to be normalized to have norm = 1 after each iteration step. Otherwise, the algorithm will not converge.
--    Normalization of a vector of numbers can be done as follows: If x = (x1; : : : ; xn) is a vector of real numbers, then its norm jxj --    is given by the formula px2 1 + · · · + x2 n. Therefore, you can normalize the vector (x1; : : : ; xn) by transforming it to the --    vector jx xj = (jxx1j + · · · + jxxnj). The norm of this vector will be 1.

-- input data
-- Same example as in video https://www.youtube.com/watch?v=jr3YGgfDY_E
-- Yahoo(1), Microsoft(2) and Amazon(3)

CREATE TABLE IF NOT EXISTS graph(source INTEGER, target INTEGER);
DELETE FROM graph;
INSERT INTO graph VALUES (1, 1);
INSERT INTO graph VALUES (1, 3);
INSERT INTO graph VALUES (1, 2);
INSERT INTO graph VALUES (2, 3);
INSERT INTO graph VALUES (3, 1);
INSERT INTO graph VALUES (3, 2);

-- hub and authority scores
CREATE TABLE IF NOT EXISTS hub(hubid INTEGER, score FLOAT);
CREATE TABLE IF NOT EXISTS authority(authid INTEGER, score FLOAT);
DELETE FROM hub;
DELETE FROM authority;

CREATE OR REPLACE VIEW G AS (SELECT hubid AS idx 
                                 FROM hub 
                             UNION 
                              SELECT authid AS idx 
                               FROM authority
                             ORDER BY idx);
                                            
CREATE OR REPLACE FUNCTION HITS_authority_hubs_algorithm(no_of_iterations INTEGER)
RETURNS VOID AS
$$ DECLARE
		   norm FLOAT;
           r_auth FLOAT;
           q_hub FLOAT;
           sq_p_auth FLOAT;
           sq_p_hub FLOAT;
		   p G%rowtype;
		   q graph%rowtype;
	       r graph%rowtype;
   BEGIN                                     
        -- Created from psuedocode provided on https://en.wikipedia.org/wiki/HITS_algorithm
        -- Initialize both scores as 1
        INSERT INTO hub(hubid, score) SELECT DISTINCT source, 1 FROM graph;
        INSERT INTO authority(authid, score) SELECT DISTINCT target, 1 FROM graph;
        -- run the algorithm for 'no_of_iterations' steps
        FOR k in 0..no_of_iterations
        LOOP
            norm = 0;
            FOR p IN SELECT idx FROM G
            LOOP
                -- update all authority values first
                UPDATE authority SET score = 0 WHERE authid = p.idx;
                -- incoming neighbors for p
                FOR q IN SELECT * FROM graph WHERE target = p.idx
                LOOP
                    SELECT score INTO q_hub 
					 FROM hub WHERE hubid = q.source;
					UPDATE authority SET score = score + q_hub WHERE authid = p.idx;	
				END LOOP;
                -- calculate the sum of the squared auth values to normalise
                SELECT score INTO sq_p_auth 
				 FROM authority WHERE authid = p.idx;
				norm = norm + POWER(sq_p_auth, 2);
            END LOOP;
            norm = POWER(norm, 0.5);
            
            -- update the auth scores     
            FOR p IN SELECT idx FROM G
            LOOP
            	-- normalise the auth values
                UPDATE authority SET score = score/norm WHERE authid = p.idx;
            END LOOP;
            
            norm = 0;
            -- then update all hub values
            FOR p IN SELECT idx FROM G
            LOOP
                UPDATE hub SET score = 0 WHERE hubid = p.idx;
                -- outgoing neighbors for p
                FOR r IN SELECT * FROM graph WHERE source = p.idx
				LOOP
                    SELECT score INTO r_auth 
					 FROM authority WHERE authid = r.target;
					UPDATE hub SET score = score + r_auth WHERE hubid = p.idx;
				END LOOP;
                -- calculate the sum of the squared hub values to normalise
				SELECT score INTO sq_p_hub FROM hub WHERE hubid = p.idx;
				norm = norm + POWER(sq_p_hub, 2);
            END LOOP;
            
            norm = POWER(norm, 0.5);        
            -- then update all hub values
            FOR p IN SELECT idx FROM G
            LOOP
            	-- normalise the hub values
                UPDATE hub SET score = score/norm WHERE hubid = p.idx;
            END LOOP;
        END LOOP;
	END;
$$ LANGUAGE plpgsql;

SELECT HITS_authority_hubs_algorithm(10);

SELECT * FROM hub;

SELECT * FROM authority;
