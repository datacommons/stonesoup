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
INSERT INTO units_taggables(id, taggable_id, taggable_type) SELECT docid as id, taggable_id, taggable_type FROM units;

CREATE TABLE IF NOT EXISTS sources (name,'key',name_of_organization,description,source_directory_link,source_info_link);
CREATE INDEX sources_key on sources(key);
CREATE INDEX sources_name on sources(name);

 -- This could do with an explanation
ALTER TABLE organizations ADD COLUMN grouping;
-- UPDATE organizations SET grouping = (select o2.id from organizations as o2 where o2.source_grouping = organizations.source_grouping order by o2.id limit 1);
UPDATE organizations SET grouping = organizations.id;

create index ii1 on locations(taggable_id, taggable_type);
create index ii2 on product_services(organization_id);
create index ii3 on organizations_sectors(organization_id);
create index ii4 on organizations_sectors(sector_id);
create index ii5 on organizations_people(person_id);
create index ii6 on organizations_people(organization_id);

create index it1 on tags(name);
create index it2 on tags(root_id, root_type);
create index it3 on tags(parent_id);

create index itt1 on taggings(tag_id);
create index itt2 on taggings(taggable_id, taggable_type);

create index itc on tag_contexts(name);
create index itw on tag_worlds(name);

create index idsot1 on data_sharing_orgs_taggables(data_sharing_org_id);
create index idsot2 on data_sharing_orgs_taggables(taggable_type);
create index idsot3 on data_sharing_orgs_taggables(taggable_id, taggable_type);
EOF
) | sqlite3 stonesoup.sqlite3
