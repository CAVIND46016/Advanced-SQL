--    Suppose you have a weighted undirected graph Graph = (V; E) stored in a ternary table named Graph in your database. A triple (n; m; --    w) in Graph indicates that Graph has an edge (n; m) where n is the source, m is the target, and w is the edge’s weight. (In this --    problem, we will assume that each edge-weight is a positive integer.) Since the graph is undirected, whenever there is an edge (n; --    m; w) in the graph, then (m; n; w) is also in the graph. Below is an example of a graph Graph.
--    Graph
--    Source Target Weight
--     0 1 2
--     1 0 2
--     0 4 10
--     4 0 10
--     1 3 3
--     3 1 3
--     1 4 7
--     4 1 7
--     2 3 4
--     3 2 4
--     3 4 5
--     4 3 5
--     4 2 6
--     2 4 6
--     A spanning tree T of Graph is a sub-graph of Graph that is acyclic and such that for each node n in Graph there is an edge in T of --     the form (n; m) or (m; n). I.e., each node of Graph is the end point of an edge in Graph. The weight of a sub-graph of Graph is --     the sum of the weights of the edges of that sub-graph. A minimum spanning tree of Graph is a spanning tree of Graph of minimum cost.
--     Write a Postgres program that determines a minimum spanning tree of a graph Graph. You can use Prim’s Algorithm to determine a --     spanning tree. Consult https://en.wikipedia.org/wiki/Minimum spanning tree and https://en.wikipedia.org/wiki/Prim’s algorithm.

-- Input data:
CREATE TABLE IF NOT EXISTS graph6(source INTEGER, target INTEGER, weight INTEGER);
DELETE FROM graph6;
INSERT INTO graph6 VALUES (0, 1, 2);
INSERT INTO graph6 VALUES (1, 0, 2);
INSERT INTO graph6 VALUES (0, 4, 10);
INSERT INTO graph6 VALUES (4, 0, 10);
INSERT INTO graph6 VALUES (1, 3, 3);
INSERT INTO graph6 VALUES (3, 1, 3);
INSERT INTO graph6 VALUES (1, 4, 7);
INSERT INTO graph6 VALUES (4, 1, 7);
INSERT INTO graph6 VALUES (2, 3, 4);
INSERT INTO graph6 VALUES (3, 2, 4);
INSERT INTO graph6 VALUES (3, 4, 5);
INSERT INTO graph6 VALUES (4, 3, 5);
INSERT INTO graph6 VALUES (4, 2, 6);
INSERT INTO graph6 VALUES (2, 4, 6);

-- http://www.mathcs.emory.edu/~cheung/Courses/171/Syllabus/11-Graph/prim2.html
CREATE OR REPLACE FUNCTION Prims_algorithm()
RETURNS VOID AS 
$$ DECLARE
           i INTEGER;
           j INTEGER;
           k INTEGER;
           x_start INTEGER;
           y_start INTEGER;
           x INTEGER;
           y INTEGER;
           w INTEGER;
           nodes INTEGER;
           reached BOOLEAN[];
           link_cost_i_j INTEGER;
           link_cost_x_y INTEGER;
           max_val INTEGER = 99999;
	BEGIN
        CREATE TABLE IF NOT EXISTS min_spanning_tree(source INTEGER, target INTEGER, weight INTEGER);
        DELETE FROM min_spanning_tree;
        -- number of nodes
   		SELECT INTO nodes COUNT(DISTINCT source) FROM graph6;
        -- set of nodes reached, with '0' considered as start position reached node.
        reached = array_fill(FALSE, ARRAY[nodes]);
        reached[1] = TRUE;
         -- Loop 'nodes-1' times
        FOR k IN 1..nodes
        LOOP
        	SELECT INTO x MIN(source) FROM graph6;
            SELECT INTO y MIN(source) FROM graph6;
            x_start := x;
            y_start := y;
            FOR i in 0..nodes+1
            LOOP
            	FOR j IN 0..nodes+1
            	LOOP
                	IF i <> j THEN
                        SELECT weight INTO link_cost_i_j FROM graph6 WHERE source = i AND target = j;
                        SELECT weight INTO link_cost_x_y FROM graph6 WHERE source = x AND target = y;
                        IF link_cost_i_j IS NULL THEN
                            link_cost_i_j = max_val;
                        END IF;
                        IF link_cost_x_y IS NULL THEN
                            link_cost_x_y = max_val;
                        END IF;
                        IF x_start = 0 AND y_start = 0 THEN
                        	IF reached[i+1] AND NOT reached[j+1] AND link_cost_i_j < link_cost_x_y THEN
                                x = i;
                                y = j;
                             END IF;
                        END IF;
                        IF x_start <> 0 OR y_start <> 0 THEN
                            IF reached[i] AND NOT reached[j] AND link_cost_i_j < link_cost_x_y THEN
                                x = i;
                                y = j;
                            END IF;
                        END IF;
                    END IF;
            	END LOOP;
            END LOOP;  
            INSERT INTO min_spanning_tree 
            SELECT source, target, weight 
             FROM graph6 
              WHERE source = x AND target = y AND weight IS NOT NULL;
            INSERT INTO min_spanning_tree 
            SELECT target, source, weight 
             FROM graph6 
              WHERE source = x AND target = y AND weight IS NOT NULL;
            IF x_start = 0 AND y_start = 0 THEN
            	reached[y+1] = True;
            END IF;
            IF x_start <> 0 OR y_start <> 0 THEN
            	reached[y] = True;
             END IF;
        END LOOP;   
    END;
$$ LANGUAGE plpgsql;

SELECT Prims_algorithm();

SELECT * FROM min_spanning_tree;
