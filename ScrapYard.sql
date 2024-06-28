-- For Testing, debugging, and Misc. Sql Operations



select * from AttendanceApproved att where att.name like 'Adrienne Belle Alexis' and att.[date] = '2024-06-19'

SELECT att.name, att.Date, att.RegularHrs, att.Overtime, att.TotalHours , att.TimeOff, att.policy_name, att.Holiday  FROM AttendanceApproved att
            WHERE att.Date BETWEEN '2024-06-16' AND '2024-06-22'

            Union ALL

            Select tt.name,Null, Sum(tt.RegularHrs), Sum(tt.Overtime), Sum(tt.TotalHours), Sum(tt.TimeOff), 'Policy_name', 'Holiday' From AttendanceApproved tt
            WHERE [Date] BETWEEN '2024-06-16' AND '2024-06-22'
            Group By tt.name

            ORDER BY [name], Date DESC

            Select * from Lem


SELECT table_name
FROM information_schema.tables


Select * from LemSheet