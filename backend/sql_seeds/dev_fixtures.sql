-- Insert dummy data
INSERT INTO fixtures.manufacturer (name)
VALUES
('Cameo'),
('Blue Sea'),
('ADJ'),
('Martin');

INSERT INTO fixtures.fixture_type (name)
VALUES
('Light'),
('Speaker');

INSERT INTO fixtures.fixture_model (manufacturer_id, fixture_type_id, model_name, short_name, power_peak_amps, usual_dmx_mode, notes) VALUES 
(
    '1', '1', 'Thunder Wash 600 RGBW', 'Thunderwash', 0.70, '7 Channel 2', ''
),
(
    '2', '1', '19pcs 15w LED Wash Zoom', 'Moving Wash?', 1.00, '14 Channel', ''
),
(
    '3', '1', 'Vizi Beam CMY', 'Beams', 1.70, '24 Channel', ''
),
(
    '3', '1', 'Inno Color Beam Z7', 'Color Beam?', 1.00, '14 Channel', ''
),
(
    '4', '1', 'Atomic 3000', 'Strobe', 2.80, '4 Channels', ''
),
(
    '2', '1', 'LED Par 18x18 IP', 'Par Led', 1.00, '10 Channels', ''
),
(
    '2', '1', '250W Beam Moving Head Light', 'Moving Head?', 1.10, '20 Channel', ''
),
(
    '1', '1', 'CL PixBar 600 Pro', 'LedBar', 1.30, '78 Channel', ''
),
(
    '2', '1', '200W LED Spotlight', 'Fresnel', 0.90, '3 Channel ', ''
);