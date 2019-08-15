#!/bin/bash

(
cat<<EOF
 -- Regular search index
DROP TABLE IF EXISTS units;
CREATE VIRTUAL TABLE units USING fts4(taggable_id, taggable_type,
       name,
       description,
       phone,
       email,
       website,
       physical,
       mailing,
       notindexed=taggable_id, notindexed=taggable_type);
INSERT INTO units(taggable_id,taggable_type,name,description,phone,email,website,physical,mailing) SELECT organizations.id as taggable_id, 'Organization' as taggable_type, name, description, phone, email, website, group_concat(printf("%s %s %s %s %s %s", physical_address1, physical_address2, physical_city, physical_state, physical_zip, physical_country), ' /// '), group_concat(printf("%s %s %s %s %s %s", mailing_address1, mailing_address2, mailing_city, mailing_state, mailing_zip, mailing_country), '///') FROM organizations left join locations on locations.taggable_id = organizations.id group by organizations.id;
INSERT INTO units(taggable_id,taggable_type,name,description) SELECT id as taggable_id, 'Person' as taggable_type, coalesce(firstname,'') || ' ' || coalesce(lastname,''), '' FROM people;

 -- I have no memory of what units_taggables is about
DROP TABLE IF EXISTS units_taggables;
CREATE TABLE units_taggables(
   id INTEGER NOT NULL,
   taggable_id INTEGER NOT NULL,
   taggable_type TEXT NOT NULL,
   PRIMARY KEY (id)
);
CREATE INDEX idx_units_taggables_out ON units_taggables(taggable_id, taggable_type);
-- CREATE INDEX idx_units_taggables_out ON units_taggables(taggable_id, taggable_type);
INSERT INTO units_taggables(id, taggable_id, taggable_type) SELECT docid as id, taggable_id, taggable_type FROM units;

CREATE TABLE IF NOT EXISTS sources (name,'key',name_of_organization,description,source_directory_link,source_info_link);
CREATE INDEX sources_key on sources(key);
CREATE INDEX sources_name on sources(name);
-- CREATE INDEX sources_key on sources(key);
-- CREATE INDEX sources_name on sources(name);

 -- This could do with an explanation
ALTER TABLE organizations ADD COLUMN grouping;
-- UPDATE organizations SET grouping = (select o2.id from organizations as o2 where o2.source_grouping = organizations.source_grouping order by o2.id limit 1);
UPDATE organizations SET grouping = organizations.id;

CREATE INDEX ix_access_rules_87ea5dfc8b8e384d ON access_rules (id);
CREATE INDEX ix_data_sharing_orgs_6ae999552a0d2dca ON data_sharing_orgs (name);
CREATE INDEX ix_data_sharing_orgs_1d6d94da1e93927d ON data_sharing_orgs (dccid);
CREATE INDEX ix_org_types_6ae999552a0d2dca ON org_types (name);
CREATE INDEX ix_sectors_6ae999552a0d2dca ON sectors (name);
CREATE INDEX ix_legal_structures_6ae999552a0d2dca ON legal_structures (name);
CREATE INDEX ix_member_orgs_6ae999552a0d2dca ON member_orgs (name);
CREATE INDEX ix_organizations_1d6d94da1e93927d ON organizations (dccid);
CREATE INDEX ix_locations_1d6d94da1e93927d ON locations (dccid);
CREATE INDEX ix_taggings_1d6d94da1e93927d ON taggings (dccid);
CREATE INDEX ix_data_sharing_orgs_taggables_1d6d94da1e93927d ON data_sharing_orgs_taggables (dccid);
CREATE INDEX ix_oids_1d6d94da1e93927d ON oids (dccid);
CREATE INDEX ix_organizations_2118c8699c550662 ON organizations (oid);
CREATE INDEX ix_data_sharing_orgs_taggables_90868c357657838e ON data_sharing_orgs_taggables (data_sharing_org_id, taggable_id, taggable_type);
CREATE INDEX ix_taggings_94bc7f962f82a803 ON taggings (tag_id, taggable_id, taggable_type);
CREATE INDEX data_sharing_orgs_key on data_sharing_orgs(key);

create index ii1 on locations(taggable_id, taggable_type);
-- CREATE INDEX ix_locations_0a6e8b1431918283 ON locations (taggable_id, taggable_type);
create index ii2 on product_services(organization_id);
-- CREATE INDEX ix_product_services_472c1f99a32def1b ON product_services (organization_id);
create index ii3 on organizations_sectors(organization_id);
create index ii4 on organizations_sectors(sector_id);
create index ii5 on organizations_people(person_id);
create index ii6 on organizations_people(organization_id);
-- CREATE INDEX ix_organizations_sectors_472c1f99a32def1b ON organizations_sectors (organization_id);
-- CREATE INDEX ix_organizations_sectors_668b2ea8a2f53442 ON organizations_sectors (sector_id);
-- CREATE INDEX ix_organizations_people_472c1f99a32def1b ON organizations_people (organization_id);
-- CREATE INDEX ix_organizations_people_5fdaf670315c4b7e ON organizations_people (person_id);

create index it1 on tags(name);
create index it2 on tags(root_id, root_type);
create index it3 on tags(parent_id);
-- CREATE INDEX ix_tags_6ae999552a0d2dca ON tags (name);
-- CREATE INDEX ix_tags_c51485bf1a773cf3 ON tags (root_id, root_type);
-- CREATE INDEX ix_tags_bf93c41ee1ae1649 ON tags (parent_id);

create index itt1 on taggings(tag_id);
create index itt2 on taggings(taggable_id, taggable_type);
-- CREATE INDEX ix_taggings_8e4052373c579afc ON taggings (tag_id);
-- CREATE INDEX ix_taggings_0a6e8b1431918283 ON taggings (taggable_id, taggable_type);

create index itc on tag_contexts(name);
create index itw on tag_worlds(name);
-- CREATE INDEX ix_tag_contexts_6ae999552a0d2dca ON tag_contexts (name);
-- CREATE INDEX ix_tag_worlds_6ae999552a0d2dca ON tag_worlds (name);

create index idsot1 on data_sharing_orgs_taggables(data_sharing_org_id);
create index idsot2 on data_sharing_orgs_taggables(taggable_type);
create index idsot3 on data_sharing_orgs_taggables(taggable_id, taggable_type);
-- CREATE INDEX ix_data_sharing_orgs_taggables_e83626ab466411b8 ON data_sharing_orgs_taggables (data_sharing_org_id);
-- CREATE INDEX ix_data_sharing_orgs_taggables_b16ab217725cad65 ON data_sharing_orgs_taggables (taggable_type);
-- CREATE INDEX ix_data_sharing_orgs_taggables_0a6e8b1431918283 ON data_sharing_orgs_taggables (taggable_id, taggable_type);

ALTER TABLE data_sharing_orgs ADD COLUMN key;
EOF
) | sqlite3 stonesoup.sqlite3
