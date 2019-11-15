CREATE TABLE Project (
project_id INT,
employee_id INT
);

CREATE TABLE Employee (
employee_id INT,
name VARCHAR(16),
experience_years INT
);


INSERT INTO Project (project_id, employee_id) VALUES (1, 1);
INSERT INTO Project (project_id, employee_id) VALUES (2, 3);
INSERT INTO Project (project_id, employee_id) VALUES (2, 4);



INSERT INTO Employee (employee_id, name, experience_years) VALUES (1, "Khaled", 3);
INSERT INTO Employee (employee_id, name, experience_years) VALUES (2, "Ali", 2);
INSERT INTO Employee (employee_id, name, experience_years) VALUES (3, "John", 1);
INSERT INTO Employee (employee_id, name, experience_years) VALUES (4, "Doe", 2);


{"headers":{
  "Project":["project_id","employee_id"],
  "Employee":["employee_id","name","experience_years"]},
  "ROWS":{
    "Project":[[1,1],[2,3],[2,4]],
    "Employee":[[1,"Khaled",3],[2,"Ali",2],[3,"John",1],[4,"Doe",2]]}}

SELECT
  Project.project_id AS project_id, e.employee_id, e.experience_years
FROM
  Project
LEFT JOIN
  Employee AS e
ON
  Project.employee_id = e.employee_id
  AND
  e.experience_years = (
    SELECT
      Employee.experience_years
    FROM
      Employee
    JOIN
      Project
    ON
      Project.employee_id = Employee.employee_id
    WHERE
      Project.project_id = project_id
    ORDER BY
      experience_years DESC
    LIMIT
      1
    )
;


SELECT
  Project.project_id, Project.employee_id
FROM
  Project
INNER JOIN
  (SELECT
    project_id, MAX(Employee.experience_years) AS xp
  FROM
    Project
  JOIN
    Employee
  ON
    Employee.employee_id = Project.employee_id
  GROUP BY
    project_id
  )
  AS
    maxes
ON
  maxes.project_id = Project.project_id
INNER JOIN
  Employee
ON
  Project.employee_id = Employee.employee_id
  AND
  Employee.experience_years = maxes.xp
;
