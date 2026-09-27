-- MakerMatch · Phase 1 · Reference data
--
-- Data every environment needs (production included): states, categories,
-- certifications and matching weights. Sample companies and test logins live in
-- supabase/seed.sql instead, which is never applied to production.
--
-- Hindi names are a first draft; have a native speaker review them before launch.

-- States and union territories with GST state codes (codes 25 and 28 are retired).
insert into public.indian_states (code, gst_code, name, is_union_territory) values
  ('JK', '01', 'Jammu and Kashmir', true),
  ('HP', '02', 'Himachal Pradesh', false),
  ('PB', '03', 'Punjab', false),
  ('CH', '04', 'Chandigarh', true),
  ('UK', '05', 'Uttarakhand', false),
  ('HR', '06', 'Haryana', false),
  ('DL', '07', 'Delhi', true),
  ('RJ', '08', 'Rajasthan', false),
  ('UP', '09', 'Uttar Pradesh', false),
  ('BR', '10', 'Bihar', false),
  ('SK', '11', 'Sikkim', false),
  ('AR', '12', 'Arunachal Pradesh', false),
  ('NL', '13', 'Nagaland', false),
  ('MN', '14', 'Manipur', false),
  ('MZ', '15', 'Mizoram', false),
  ('TR', '16', 'Tripura', false),
  ('ML', '17', 'Meghalaya', false),
  ('AS', '18', 'Assam', false),
  ('WB', '19', 'West Bengal', false),
  ('JH', '20', 'Jharkhand', false),
  ('OD', '21', 'Odisha', false),
  ('CG', '22', 'Chhattisgarh', false),
  ('MP', '23', 'Madhya Pradesh', false),
  ('GJ', '24', 'Gujarat', false),
  ('DH', '26', 'Dadra and Nagar Haveli and Daman and Diu', true),
  ('MH', '27', 'Maharashtra', false),
  ('KA', '29', 'Karnataka', false),
  ('GA', '30', 'Goa', false),
  ('LD', '31', 'Lakshadweep', true),
  ('KL', '32', 'Kerala', false),
  ('TN', '33', 'Tamil Nadu', false),
  ('PY', '34', 'Puducherry', true),
  ('AN', '35', 'Andaman and Nicobar Islands', true),
  ('TG', '36', 'Telangana', false),
  ('AP', '37', 'Andhra Pradesh', false),
  ('LA', '38', 'Ladakh', true);

-- Launch niche: food, beverage and nutrition.
insert into public.categories (slug, name, name_hi, sort_order) values
  ('beverages', 'Beverages', 'पेय पदार्थ', 1),
  ('snacks', 'Snacks', 'स्नैक्स', 2),
  ('nutrition', 'Protein & supplements', 'प्रोटीन और सप्लीमेंट', 3),
  ('dairy', 'Dairy', 'डेयरी', 4),
  ('co-packing', 'Co-packing', 'को-पैकिंग', 5);

insert into public.categories (slug, name, name_hi, parent_id, sort_order)
select v.slug, v.name, v.name_hi, p.id, v.sort_order
from (values
  ('beverages', 'carbonated-drinks', 'Carbonated soft drinks', 'कार्बोनेटेड शीतल पेय', 1),
  ('beverages', 'juices-nectars', 'Juices & nectars', 'जूस और नेक्टर', 2),
  ('beverages', 'functional-drinks', 'Functional & energy drinks', 'फंक्शनल और एनर्जी ड्रिंक', 3),
  ('beverages', 'rtd-tea-coffee', 'Ready-to-drink tea & coffee', 'रेडी-टू-ड्रिंक चाय और कॉफ़ी', 4),
  ('beverages', 'packaged-water', 'Packaged drinking water', 'पैकेज्ड पेयजल', 5),
  ('snacks', 'chips-extruded', 'Chips & extruded snacks', 'चिप्स और एक्सट्रूडेड स्नैक्स', 1),
  ('snacks', 'namkeen', 'Namkeen & traditional snacks', 'नमकीन और पारंपरिक स्नैक्स', 2),
  ('snacks', 'bakery-biscuits', 'Bakery & biscuits', 'बेकरी और बिस्कुट', 3),
  ('snacks', 'nuts-seeds-makhana', 'Roasted nuts, seeds & makhana', 'भुने मेवे, बीज और मखाना', 4),
  ('nutrition', 'protein-powders', 'Protein powders', 'प्रोटीन पाउडर', 1),
  ('nutrition', 'nutrition-bars', 'Protein & nutrition bars', 'प्रोटीन और न्यूट्रिशन बार', 2),
  ('nutrition', 'vitamins-supplements', 'Vitamins & dietary supplements', 'विटामिन और आहार पूरक', 3),
  ('nutrition', 'sports-nutrition', 'Sports nutrition & electrolytes', 'स्पोर्ट्स न्यूट्रिशन और इलेक्ट्रोलाइट', 4),
  ('nutrition', 'ayurvedic-herbal', 'Ayurvedic & herbal nutraceuticals', 'आयुर्वेदिक और हर्बल न्यूट्रास्युटिकल', 5),
  ('dairy', 'milk-flavoured-milk', 'Milk & flavoured milk', 'दूध और फ्लेवर्ड दूध', 1),
  ('dairy', 'curd-yoghurt', 'Curd, yoghurt & buttermilk', 'दही, योगर्ट और छाछ', 2),
  ('dairy', 'paneer-cheese', 'Paneer & cheese', 'पनीर और चीज़', 3),
  ('dairy', 'ghee-butter', 'Ghee & butter', 'घी और मक्खन', 4),
  ('dairy', 'ice-cream-frozen', 'Ice cream & frozen desserts', 'आइसक्रीम और फ्रोज़न डेज़र्ट', 5),
  ('dairy', 'plant-based-dairy', 'Plant-based dairy alternatives', 'प्लांट-बेस्ड डेयरी विकल्प', 6),
  ('co-packing', 'beverage-bottling', 'Beverage bottling & canning', 'पेय बॉटलिंग और कैनिंग', 1),
  ('co-packing', 'powder-filling', 'Powder filling & sachets', 'पाउडर फिलिंग और सैशे', 2),
  ('co-packing', 'snack-packing', 'Snack & dry food packing', 'स्नैक और सूखे खाद्य की पैकिंग', 3)
) as v (parent_slug, slug, name, name_hi, sort_order)
join public.categories p on p.slug = v.parent_slug;

insert into public.certifications (code, name, description) values
  ('fssai', 'FSSAI licence', 'Food Safety and Standards Authority of India licence (State or Central).'),
  ('iso-22000', 'ISO 22000', 'Food safety management system.'),
  ('fssc-22000', 'FSSC 22000', 'GFSI-recognised food safety scheme built on ISO 22000.'),
  ('haccp', 'HACCP', 'Hazard Analysis and Critical Control Points.'),
  ('gmp', 'GMP', 'Good Manufacturing Practice.'),
  ('brcgs', 'BRCGS Food Safety', 'Often required by UK and EU retail buyers.'),
  ('halal', 'Halal', 'Halal certification.'),
  ('india-organic', 'India Organic (NPOP)', 'National Programme for Organic Production / Jaivik Bharat.'),
  ('usda-organic', 'USDA Organic', 'For organic exports to the US.'),
  ('bis', 'BIS certification', 'Bureau of Indian Standards, e.g. IS 14543 for packaged drinking water.'),
  ('ayush', 'AYUSH manufacturing licence', 'For Ayurvedic and herbal products.'),
  ('us-fda', 'US FDA registered facility', 'Food facility registration for exports to the US.');

insert into public.match_weights (factor, weight, description) values
  ('capability', 35, 'Overlap between brief specs (format, packaging, process) and manufacturer capabilities'),
  ('capacity', 20, 'Brief volume vs monthly capacity; best when the order is a meaningful but not overwhelming share'),
  ('responsiveness', 20, 'Response rate and median reply time over the last 90 days'),
  ('distance', 15, 'Closer to the founder''s city scores higher; same state gets a bonus'),
  ('formulation', 10, 'Full points if the founder needs R&D help and the manufacturer offers it');
