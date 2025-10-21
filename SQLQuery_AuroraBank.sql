
SELECT * FROM cards_data
SELECT * FROM transactions_data
SELECT * FROM users_data
SELECT * FROM mcc_codes

ALTER TABLE transactions_data
ADD CONSTRAINT PK_transactions_data PRIMARY KEY (id);
