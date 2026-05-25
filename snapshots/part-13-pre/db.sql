--
-- PostgreSQL database dump
--

\restrict qH03WzzydgH8ScXxSpTeRw2F0OlggDHzpL6Fr7C4BL7EbtHFj9fOfJv4yXFysRw

-- Dumped from database version 16.14 (Debian 16.14-1.pgdg12+1)
-- Dumped by pg_dump version 16.14 (Debian 16.14-1.pgdg12+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: contact_inboxes; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.contact_inboxes (id, contact_id, inbox_id, source_id, created_at, updated_at, hmac_verified, pubsub_token) FROM stdin;
13	11	12	e9763563-dc5e-4ba5-8390-ef33dc9f3f74	2026-05-25 00:03:40.172376	2026-05-25 00:03:40.172376	f	SFH3UsYUJs7CsSnuqWZpf5kN
14	11	11	d0d99c2b-32d6-4d34-9813-813f27c36c9b	2026-05-25 00:06:59.045775	2026-05-25 00:06:59.045775	f	gkD8ACDuvHSHvyrjAfY6GmBQ
\.


--
-- Data for Name: contacts; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.contacts (id, name, email, phone_number, account_id, created_at, updated_at, additional_attributes, identifier, custom_attributes, last_activity_at, contact_type, middle_name, last_name, location, country_code, blocked, company_id) FROM stdin;
1	EvolutionAPI	\N	+123456	1	2026-05-22 20:37:58.540669	2026-05-22 20:49:58.981572	{"avatar_url_hash": "245e493457bbe42981ae8bafe6c05adaa8dedbf5c5fa20ab2b9e807d1f5ada57", "last_avatar_sync_at": "2026-05-22T20:38:30Z"}	\N	{}	2026-05-22 20:49:58.966022	1			\N	\N	f	\N
2	Smoke P4	smoke-p4@test.com	\N	1	2026-05-24 18:22:38.365897	2026-05-24 18:22:38.365897	{"avatar_url_hash": "2ab3f752fef0aa350507cfeff6c4e96780c5496b6d4519a96dcef5d6b18e388e", "last_avatar_sync_at": "2026-05-24T18:23:14Z"}	\N	{}	\N	1			\N	\N	f	\N
3	Cliente Teste	\N	+5511888888888	1	2026-05-24 18:41:31.592206	2026-05-24 18:41:31.592206	{}	\N	{}	\N	1			\N	\N	f	\N
4	Smoke P5	\N	+5511777000001	1	2026-05-24 18:50:14.741663	2026-05-24 18:50:14.741663	{}	\N	{}	\N	1			\N	\N	f	\N
5	Foto Test	\N	+5511777777777	1	2026-05-24 18:54:37.614306	2026-05-24 18:54:37.614306	{}	\N	{}	\N	1			\N	\N	f	\N
6	Foto Test 2	\N	+5511666666666	1	2026-05-24 19:02:11.396032	2026-05-24 19:02:11.396032	{}	\N	{}	\N	1			\N	\N	f	\N
7	Foto Test 3	\N	+5511555555555	1	2026-05-24 19:04:26.346309	2026-05-24 19:04:26.346309	{}	\N	{}	\N	1			\N	\N	f	\N
8	Smoke P6	\N	+5511444000001	1	2026-05-24 19:08:31.219801	2026-05-24 19:08:31.219801	{}	\N	{}	\N	1			\N	\N	f	\N
9	Self Test	\N	+5541999953255	1	2026-05-24 19:25:16.147235	2026-05-24 19:25:16.147235	{}	\N	{}	\N	1			\N	\N	f	\N
10	Guard Test	\N	+5511000099999	1	2026-05-24 19:30:20.216981	2026-05-24 19:30:20.216981	{}	\N	{}	\N	1			\N	\N	f	\N
11	Mello	\N	+554199953255	1	2026-05-25 00:03:40.058203	2026-05-25 00:03:40.058203	{}	\N	{}	\N	1			\N	\N	f	\N
\.


--
-- Data for Name: conversations; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.conversations (id, account_id, inbox_id, status, assignee_id, created_at, updated_at, contact_id, display_id, contact_last_seen_at, agent_last_seen_at, additional_attributes, contact_inbox_id, uuid, identifier, last_activity_at, team_id, campaign_id, snoozed_until, custom_attributes, assignee_last_seen_at, first_reply_created_at, priority, sla_policy_id, waiting_since, cached_label_list, assignee_agent_bot_id) FROM stdin;
13	1	11	0	1	2026-05-25 00:06:59.079499	2026-05-25 00:06:59.846364	11	13	\N	2026-05-25 01:23:50.448993	{"mail_subject": "undefined"}	14	cf84a2c3-0f33-424a-8ded-d3c2a3838016	\N	2026-05-25 00:06:59.698146	\N	\N	\N	{}	2026-05-25 01:23:50.448993	2026-05-25 00:06:59.140955	\N	\N	\N		\N
14	1	12	0	1	2026-05-25 01:26:32.511965	2026-05-25 01:26:34.149275	11	14	\N	2026-05-25 01:26:36.187784	{"mail_subject": "undefined"}	13	3260db78-1fb7-4f1f-b553-7b3f50a2bf34	\N	2026-05-25 01:26:33.867416	\N	\N	\N	{}	2026-05-25 01:26:36.187784	2026-05-25 01:26:32.640473	\N	\N	\N		\N
12	1	12	0	\N	2026-05-25 00:03:40.27803	2026-05-25 00:03:40.565565	11	12	\N	2026-05-25 00:05:37.06474	{"source": "whatsapp_lite"}	13	02eed240-88a5-4797-8fe8-eef5b85b2607	\N	2026-05-25 00:03:40.558353	\N	\N	\N	{}	\N	\N	\N	\N	2026-05-25 00:03:40.27803	\N	\N
\.


--
-- Data for Name: inboxes; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.inboxes (id, channel_id, account_id, name, created_at, updated_at, channel_type, enable_auto_assignment, greeting_enabled, greeting_message, email_address, working_hours_enabled, out_of_office_message, timezone, enable_email_collect, csat_survey_enabled, allow_messages_after_resolved, auto_assignment_config, lock_to_single_conversation, portal_id, sender_name_type, business_name, csat_config) FROM stdin;
4	4	1	WA Teste P7	2026-05-24 19:24:15.389699	2026-05-24 19:24:15.389699	Channel::Api	t	f	\N	\N	f	\N	UTC	t	f	t	{}	f	\N	0	\N	{}
9	9	1	WhatsApp +5541800099901	2026-05-24 19:54:31.644607	2026-05-24 19:54:31.644607	Channel::Api	t	f	\N	\N	f	\N	UTC	t	f	t	{}	f	\N	0	\N	{}
11	11	1	WhatsApp +5541996795835	2026-05-24 20:57:37.039379	2026-05-24 20:57:37.039379	Channel::Api	t	f	\N	\N	f	\N	UTC	t	f	t	{}	f	\N	0	\N	{}
12	12	1	WhatsApp +5511981199529	2026-05-24 21:00:03.529045	2026-05-24 21:00:03.529045	Channel::Api	t	f	\N	\N	f	\N	UTC	t	f	t	{}	f	\N	0	\N	{}
13	13	1	WhatsApp +5541988102020	2026-05-24 21:04:24.663979	2026-05-24 21:04:24.663979	Channel::Api	t	f	\N	\N	f	\N	UTC	t	f	t	{}	f	\N	0	\N	{}
14	14	1	WhatsApp +555541999953255	2026-05-24 21:14:07.035265	2026-05-24 21:14:07.035265	Channel::Api	t	f	\N	\N	f	\N	UTC	t	f	t	{}	f	\N	0	\N	{}
15	15	1	WhatsApp +5541999953255	2026-05-24 21:14:35.777767	2026-05-24 21:14:35.777767	Channel::Api	t	f	\N	\N	f	\N	UTC	t	f	t	{}	f	\N	0	\N	{}
17	17	1	WhatsApp +5541997930037	2026-05-25 01:28:50.095814	2026-05-25 01:28:50.095814	Channel::Api	t	f	\N	\N	f	\N	UTC	t	f	t	{}	f	\N	0	\N	{}
\.


--
-- Data for Name: whatsapp_lite_channels; Type: TABLE DATA; Schema: public; Owner: opp4s
--

COPY public.whatsapp_lite_channels (id, account_id, inbox_id, instance_id, phone_number, status, qr_expires_at, created_at, updated_at, deleted_at) FROM stdin;
12	1	4	3255_pessoal	+5541999953255	4	\N	2026-05-24 19:24:15.599975	2026-05-25 01:16:02.578255	2026-05-25 01:16:02.549553
25	1	13	cw-1-5541988102020	+5541988102020	4	2026-05-24 22:56:37	2026-05-24 21:04:24.721746	2026-05-25 01:18:23.258594	2026-05-25 01:18:23.240258
27	1	15	cw-1-5541999953255	+5541999953255	4	2026-05-24 21:16:06	2026-05-24 21:14:35.833041	2026-05-25 01:19:08.945628	2026-05-25 01:19:08.931129
26	1	14	cw-1-555541999953255	+555541999953255	4	2026-05-24 21:15:37	2026-05-24 21:14:07.100369	2026-05-25 01:19:28.903819	2026-05-25 01:19:28.897706
23	1	11	cw-1-5541996795835	+5541996795835	4	2026-05-24 23:58:17	2026-05-24 20:57:37.095049	2026-05-25 01:19:34.049958	2026-05-25 01:19:34.031705
24	1	12	cw-1-5511981199529	+5511981199529	2	2026-05-25 01:23:09	2026-05-24 21:00:03.615549	2026-05-25 01:22:36.743171	2026-05-25 01:21:50.808979
29	1	17	cw-1-5541997930037	+5541997930037	0	2026-05-25 01:29:40	2026-05-25 01:28:50.228088	2026-05-25 01:30:06.654611	\N
\.


--
-- Name: contact_inboxes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.contact_inboxes_id_seq', 14, true);


--
-- Name: contacts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.contacts_id_seq', 11, true);


--
-- Name: conversations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.conversations_id_seq', 14, true);


--
-- Name: inboxes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.inboxes_id_seq', 17, true);


--
-- Name: whatsapp_lite_channels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: opp4s
--

SELECT pg_catalog.setval('public.whatsapp_lite_channels_id_seq', 29, true);


--
-- PostgreSQL database dump complete
--

\unrestrict qH03WzzydgH8ScXxSpTeRw2F0OlggDHzpL6Fr7C4BL7EbtHFj9fOfJv4yXFysRw

