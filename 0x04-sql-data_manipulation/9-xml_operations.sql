/*
 * File: 9-xml_operations.sql
 * Description: XML data processing operations in SQL
 * Author: Alpha0-1
 * 
 * This file demonstrates XML data handling techniques including:
 * - Creating XML data
 * - Parsing XML documents
 * - Extracting XML values
 * - Modifying XML content
 * - XML validation
 */

-- Create sample table for XML operations
CREATE TABLE IF NOT EXISTS xml_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    document_name VARCHAR(100) NOT NULL,
    xml_content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample XML data
INSERT INTO xml_documents (document_name, xml_content) VALUES
('employee_record', 
'<employee>
    <id>101</id>
    <name>John Doe</name>
    <department>Engineering</department>
    <salary>75000</salary>
    <skills>
        <skill>Python</skill>
        <skill>SQL</skill>
        <skill>JavaScript</skill>
    </skills>
</employee>'),
('product_catalog', 
'<product>
    <id>P001</id>
    <name>Laptop Computer</name>
    <category>Electronics</category>
    <price currency="USD">999.99</price>
    <specifications>
        <processor>Intel i7</processor>
        <memory>16GB</memory>
        <storage>512GB SSD</storage>
    </specifications>
</product>'),
('order_details', 
'<order>
    <orderid>ORD001</orderid>
    <customer>
        <name>Jane Smith</name>
        <email>jane@email.com</email>
    </customer>
    <items>
        <item id="1" quantity="2">Widget A</item>
        <item id="2" quantity="1">Widget B</item>
    </items>
    <total>150.00</total>
</order>');

-- MySQL XML operations using ExtractValue and UpdateXML functions
-- Extract specific values from XML documents
SELECT 
    id,
    document_name,
    ExtractValue(xml_content, '//name') as extracted_name,
    ExtractValue(xml_content, '//id') as extracted_id
FROM xml_documents
WHERE xml_content IS NOT NULL;

-- Extract multiple values from XML
SELECT 
    document_name,
    ExtractValue(xml_content, '//employee/name') as employee_name,
    ExtractValue(xml_content, '//employee/department') as department,
    ExtractValue(xml_content, '//employee/salary') as salary
FROM xml_documents
WHERE document_name = 'employee_record';

-- Extract attributes from XML elements
SELECT 
    document_name,
    ExtractValue(xml_content, '//price/@currency') as currency,
    ExtractValue(xml_content, '//price') as price_value
FROM xml_documents
WHERE document_name = 'product_catalog';

-- Update XML content using UpdateXML
UPDATE xml_documents 
SET xml_content = UpdateXML(
    xml_content, 
    '//employee/salary', 
    '<salary>80000</salary>'
)
WHERE document_name = 'employee_record';

-- PostgreSQL XML operations (alternative syntax)
-- Note: PostgreSQL has different XML functions
/*
-- Create table with XML data type in PostgreSQL
CREATE TABLE xml_data_pg (
    id SERIAL PRIMARY KEY,
    doc_name VARCHAR(100),
    xml_doc XML
);

-- Insert XML data in PostgreSQL
INSERT INTO xml_data_pg (doc_name, xml_doc) VALUES
('sample', '<?xml version="1.0"?>
<root>
    <person id="1">
        <name>Alice</name>
        <age>30</age>
    </person>
</root>');

-- Extract values using XPath in PostgreSQL
SELECT 
    doc_name,
    xpath('//name/text()', xml_doc) as name,
    xpath('//age/text()', xml_doc) as age
FROM xml_data_pg;
*/

-- Create a function to validate XML structure
DELIMITER //
CREATE FUNCTION ValidateEmployeeXML(xml_data TEXT)
RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE result BOOLEAN DEFAULT FALSE;
    DECLARE xml_valid BOOLEAN DEFAULT FALSE;
    
    -- Check if required elements exist
    IF ExtractValue(xml_data, 'count(//employee)') > 0 AND
       ExtractValue(xml_data, 'count(//employee/id)') > 0 AND
       ExtractValue(xml_data, 'count(//employee/name)') > 0 THEN
        SET result = TRUE;
    END IF;
    
    RETURN result;
END//
DELIMITER ;

-- Use the validation function
SELECT 
    document_name,
    ValidateEmployeeXML(xml_content) as is_valid_employee_xml
FROM xml_documents;

-- Extract all skills from employee XML
SELECT 
    document_name,
    ExtractValue(xml_content, '//skills/skill[1]') as skill_1,
    ExtractValue(xml_content, '//skills/skill[2]') as skill_2,
    ExtractValue(xml_content, '//skills/skill[3]') as skill_3
FROM xml_documents
WHERE document_name = 'employee_record';

-- Create XML from relational data
CREATE TEMPORARY TABLE temp_employees (
    emp_id INT,
    emp_name VARCHAR(50),
    department VARCHAR(50),
    salary DECIMAL(10,2)
);

INSERT INTO temp_employees VALUES
(1, 'Alice Johnson', 'HR', 65000),
(2, 'Bob Wilson', 'IT', 70000),
(3, 'Carol Davis', 'Finance', 68000);

-- Generate XML from table data
SELECT 
    CONCAT(
        '<employee>',
        '<id>', emp_id, '</id>',
        '<name>', emp_name, '</name>',
        '<department>', department, '</department>',
        '<salary>', salary, '</salary>',
        '</employee>'
    ) as generated_xml
FROM temp_employees;

-- Search within XML content
SELECT 
    document_name,
    xml_content
FROM xml_documents
WHERE ExtractValue(xml_content, '//department') = 'Engineering'
   OR ExtractValue(xml_content, '//category') = 'Electronics';

-- Count XML elements
SELECT 
    document_name,
    ExtractValue(xml_content, 'count(//skill)') as skill_count,
    ExtractValue(xml_content, 'count(//item)') as item_count
FROM xml_documents;

-- Extract and aggregate XML data
SELECT 
    'Total Salary' as metric,
    SUM(CAST(ExtractValue(xml_content, '//salary') AS DECIMAL(10,2))) as total_value
FROM xml_documents
WHERE ExtractValue(xml_content, '//salary') IS NOT NULL AND
      ExtractValue(xml_content, '//salary') != '';

-- Clean up temporary objects
DROP TEMPORARY TABLE IF EXISTS temp_employees;
DROP FUNCTION IF EXISTS ValidateEmployeeXML;

-- Performance considerations for XML operations
-- Create index on frequently searched XML content
-- ALTER TABLE xml_documents ADD INDEX idx_xml_search (
--     (ExtractValue(xml_content, '//name'))
-- );

/*
 * Best Practices for XML Operations:
 * 1. Validate XML structure before processing
 * 2. Use indexes on frequently queried XML paths
 * 3. Consider storing parsed data in separate columns for performance
 * 4. Handle NULL and empty XML gracefully
 * 5. Use proper error handling for malformed XML
 * 6. Consider using JSON instead of XML for simpler structures
 * 
 * Common Use Cases:
 * - Configuration data storage
 * - API response processing
 * - Data exchange between systems
 * - Document management systems
 * - Legacy system integration
 */
