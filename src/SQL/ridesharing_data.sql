INSERT INTO passengers VALUES(0, 'AC');
INSERT INTO passengers VALUES(1, 'ZZ');
INSERT INTO passengers VALUES(2, 'QQ');
INSERT INTO passengers VALUES(3, 'BB');
INSERT INTO passengers VALUES(4, 'DD');
INSERT INTO passengers VALUES(5, 'FF');
INSERT INTO passengers VALUES(6, 'KK');
INSERT INTO passengers VALUES(7, 'RR');
INSERT INTO passengers VALUES(8, 'AC');
INSERT INTO passengers VALUES(9, 'AA');
INSERT INTO passengers VALUES(10, 'BBC');
INSERT INTO passengers VALUES(11, 'ANJH');

INSERT INTO drivers VALUES(1, 'ABCD', 'qfsjafhaf', '000000000');
INSERT INTO drivers VALUES(2, 'jjjjj', 'aaaaaaaa', '1111111111');
INSERT INTO drivers VALUES(3, 'iiiii', 'bbbbbbbb', '2222222222');
INSERT INTO drivers VALUES(4, 'hhhhh', 'cdcdcdcd', '3333333333');
INSERT INTO drivers VALUES(5, 'ggggg', 'efefefefe', '444444444');
INSERT INTO drivers VALUES(6, 'bbb', 'fgfgfgfgfgf', '555555555');
INSERT INTO drivers VALUES(7, 'ccccc', 'nmnmnmnmnm', '666666666');
INSERT INTO drivers VALUES(8, 'ddddd', 'zxzxzxzxzxz', '777777777');
INSERT INTO drivers VALUES(9, 'eeeee', 'qwqwqwqwqwq', '888888888');
INSERT INTO drivers VALUES(10, 'fffff', 'oppoooppopo', '999999999');

INSERT INTO locations VALUES(1, 0.0111111, 0.03531);
INSERT INTO locations VALUES(2, 0.0222222, 0.018831);
INSERT INTO locations VALUES(3, 0.12121212, 0.0309131);
INSERT INTO locations VALUES(4, 0.333333, 0.0323131);
INSERT INTO locations VALUES(5, 0.44444, 0.1314531);
INSERT INTO locations VALUES(6, -0.5555555, -0.1643131);
INSERT INTO locations VALUES(7, -0.666666, -0.137831);
INSERT INTO locations VALUES(8, -0.77777, -0.139831);
INSERT INTO locations VALUES(9, -0.888888, -0.1313881);
INSERT INTO locations VALUES(10, NULL, NULL);

INSERT INTO rides VALUES(DEFAULT, 1, 1, 1, 0.045664, 0.0987, 0.0655, 0.0356, DEFAULT, '2001-02-16 20:38:40', '2001-02-16 20:40:40', 'completed');
INSERT INTO rides VALUES(DEFAULT, 2, NULL, 1, 0.04546, 0.0112, 0.0123, 0.034, 0.00, NULL, NULL, 'requested');
INSERT INTO rides VALUES(DEFAULT, 3, NULL, 1, 0.04546, 0.01541, 0.0754, 0.08765, 0.00, NULL, NULL, 'requested');
INSERT INTO rides VALUES(DEFAULT, 4, NULL, 1, 0.04546, 0.067111, 0.04746, 0.04635, 0.00, NULL, NULL, 'requested');

INSERT INTO ratings VALUES(1, 5);
