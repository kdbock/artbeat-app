#!/usr/bin/env python3
"""Merge artbeat_ads translations into assets translation files and validate placeholders."""
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
EN_FILE = ROOT / "artbeat_ads_texts_data.json"
TRANSLATIONS_DIR = ROOT / "assets" / "translations"
TARGET_LANGS = ["es", "fr", "de", "pt", "zh"]

PLACEHOLDER_REGEX = re.compile(r"\{[^}]+\}|\$\{[^}]+\}|\$[a-zA-Z_]\w*")

# Translation map generated from English source — keep keys identical
TRANSLATIONS = {
    "es": {
        "ads_ad_migration_text_dry_run_results": "Resultados de ejecución",
        "ads_ad_migration_text_migration_results": "Resultados de migración",
        "ads_ad_migration_text_migration_statistics": "Estadísticas de migración",
        "ads_ad_migration_text_old_collection": "Colección anterior",
        "ads_ad_migration_text_new_collection": "Nueva colección",
        "ads_ad_migration_text_remaining_to_migrate": "Restantes por migrar",
        "ads_ad_migration_text_about_migration": "Acerca de la migración",
        "ads_ad_migration_text_migration_description": "Esta herramienta migra anuncios de la colección antigua \"ads\" a la nueva colección \"localAds\" con el mapeo correcto de campos:\n\n• Convierte AdLocation/AdZone a LocalAdZone\n• Mapea AdStatus a LocalAdStatus\n• Agrega nuevos campos de reporte (reportCount = 0)\n• Conserva todo el contenido y los metadatos del anuncio\n• Omite anuncios que ya existen (a menos que se habilite sobrescritura)",
        "ads_ad_migration_text_migration_actions": "Acciones de migración",
        "ads_ad_migration_text_last_migration_result": "Último resultado de migración",
        "ads_ad_migration_text_total_found": "Total encontrados",
        "ads_ad_migration_text_migrated": "Migrados",
        "ads_ad_migration_text_skipped": "Omitidos",
        "ads_ad_migration_text_failed": "Fallidos",
        "ads_ad_migration_text_errors": "Errores",
        "ads_ad_migration_text_more_errors": "... y {count} más",
        "ads_ad_migration_text_overwrite_warning": "Esto SOBRESCRIBIRÁ cualquier anuncio existente en la colección localAds que tenga la misma ID que los anuncios en la colección antigua.\n\nEsta acción no se puede deshacer. ¿Seguro que quieres continuar?",
        "ads_ad_migration_text_overwrite": "Sobrescribir",
        "ads_create_local_ad_text_promote_your_art": "Promociona tu arte",
        "ads_create_local_ad_text_reach_art_lovers": "Llega a amantes del arte en áreas de alto tráfico",
        "ads_create_local_ad_text_ad_content": "Contenido del anuncio",
        "ads_create_local_ad_text_image_optional": "Imagen (Opcional)",
        "ads_create_local_ad_text_tap_to_select_image": "Toca para seleccionar imagen",
        "ads_create_local_ad_text_where_to_display": "Dónde mostrar",
        "ads_create_local_ad_text_select_zone": "Seleccionar zona",
        "ads_create_local_ad_text_size_and_duration": "Tamaño y duración",
        "ads_create_local_ad_text_select_size": "Seleccionar tamaño",
        "ads_create_local_ad_text_select_duration": "Seleccionar duración",
        "ads_create_local_ad_text_post_ad_for_price": "Publicar anuncio por ${price}",
        "ads_local_ads_list_text_no_ads_in_zone": "No hay anuncios en {zone}",
        "ads_local_ads_list_text_be_first_to_post": "¡Sé el primero en publicar!",
        "ads_my_ads_text_no_ads_yet": "Aún no hay anuncios",
        "ads_my_ads_text_post_first_ad": "Publica tu primer anuncio para comenzar",
        "ads_my_ads_text_active_ads": "Anuncios activos ({count})",
        "ads_my_ads_text_expired_ads": "Anuncios caducados ({count})",
        "ads_my_ads_text_delete": "Eliminar",
        "ads_ad_card_text_delete": "Eliminar",
        "ads_ad_carousel_text_ad": "Anuncio",
        "ads_ad_cta_text_learn_more": "Más información",
        "ads_ad_grid_text_ad": "Anuncio",
        "ads_ad_native_text_sponsored": "Patrocinado",
        "ads_ad_report_text_report_advertisement": "Denunciar anuncio",
        "ads_ad_report_text_ad_prefix": "Anuncio:",
        "ads_ad_report_text_whats_wrong": "¿Qué está mal con este anuncio?",
        "ads_ad_report_text_cancel": "Cancelar",
        "ads_ad_report_text_submit_report": "Enviar informe",
        "ads_ad_report_text_disclaimer": "Los informes son revisados por nuestro equipo de moderación. Los informes falsos pueden resultar en restricciones de cuenta.",
        "ads_ad_report_text_report_submitted": "Informe enviado con éxito. Gracias por ayudar a mantener nuestra comunidad segura.",
        "ads_ad_report_text_failed_to_submit": "Error al enviar el informe",
        "ads_ad_report_text_report": "Informe",
        "ads_ad_small_banner_text_learn": "Más",
        "ads_ad_badge_text_featured": "Destacado",
    },
    "fr": {
        "ads_ad_migration_text_dry_run_results": "Résultats de simulation",
        "ads_ad_migration_text_migration_results": "Résultats de migration",
        "ads_ad_migration_text_migration_statistics": "Statistiques de migration",
        "ads_ad_migration_text_old_collection": "Ancienne collection",
        "ads_ad_migration_text_new_collection": "Nouvelle collection",
        "ads_ad_migration_text_remaining_to_migrate": "Restant à migrer",
        "ads_ad_migration_text_about_migration": "À propos de la migration",
        "ads_ad_migration_text_migration_description": "Cet outil migre les annonces de l'ancienne collection \"ads\" vers la nouvelle collection \"localAds\" en mappant correctement les champs:\n\n• Convertit AdLocation/AdZone en LocalAdZone\n• Mappe AdStatus en LocalAdStatus\n• Ajoute de nouveaux champs de reporting (reportCount = 0)\n• Préserve tout le contenu et les métadonnées des annonces\n• Ignore les annonces déjà existantes (sauf si l'écrasement est activé)",
        "ads_ad_migration_text_migration_actions": "Actions de migration",
        "ads_ad_migration_text_last_migration_result": "Dernier résultat de migration",
        "ads_ad_migration_text_total_found": "Total trouvés",
        "ads_ad_migration_text_migrated": "Migré(s)",
        "ads_ad_migration_text_skipped": "Ignoré(s)",
        "ads_ad_migration_text_failed": "Échoué(s)",
        "ads_ad_migration_text_errors": "Erreurs",
        "ads_ad_migration_text_more_errors": "... et {count} de plus",
        "ads_ad_migration_text_overwrite_warning": "Ceci ÉCRASERA les annonces existantes dans la collection localAds qui ont le même ID que celles de l'ancienne collection.\n\nCette action est irréversible. Êtes-vous sûr de vouloir continuer?",
        "ads_ad_migration_text_overwrite": "Écraser",
        "ads_create_local_ad_text_promote_your_art": "Promouvez votre art",
        "ads_create_local_ad_text_reach_art_lovers": "Atteignez les amateurs d'art dans des zones à fort trafic",
        "ads_create_local_ad_text_ad_content": "Contenu de l'annonce",
        "ads_create_local_ad_text_image_optional": "Image (facultative)",
        "ads_create_local_ad_text_tap_to_select_image": "Appuyez pour sélectionner une image",
        "ads_create_local_ad_text_where_to_display": "Où afficher",
        "ads_create_local_ad_text_select_zone": "Sélectionner une zone",
        "ads_create_local_ad_text_size_and_duration": "Taille et durée",
        "ads_create_local_ad_text_select_size": "Sélectionner la taille",
        "ads_create_local_ad_text_select_duration": "Sélectionner la durée",
        "ads_create_local_ad_text_post_ad_for_price": "Publier l'annonce pour ${price}",
        "ads_local_ads_list_text_no_ads_in_zone": "Aucune annonce dans {zone}",
        "ads_local_ads_list_text_be_first_to_post": "Soyez le premier à publier !",
        "ads_my_ads_text_no_ads_yet": "Pas encore d'annonces",
        "ads_my_ads_text_post_first_ad": "Publiez votre première annonce pour commencer",
        "ads_my_ads_text_active_ads": "Annonces actives ({count})",
        "ads_my_ads_text_expired_ads": "Annonces expirées ({count})",
        "ads_my_ads_text_delete": "Supprimer",
        "ads_ad_card_text_delete": "Supprimer",
        "ads_ad_carousel_text_ad": "Annonce",
        "ads_ad_cta_text_learn_more": "En savoir plus",
        "ads_ad_grid_text_ad": "Annonce",
        "ads_ad_native_text_sponsored": "Sponsorisé",
        "ads_ad_report_text_report_advertisement": "Signaler une annonce",
        "ads_ad_report_text_ad_prefix": "Annonce :",
        "ads_ad_report_text_whats_wrong": "Quel est le problème avec cette annonce ?",
        "ads_ad_report_text_cancel": "Annuler",
        "ads_ad_report_text_submit_report": "Soumettre le signalement",
        "ads_ad_report_text_disclaimer": "Les signalements sont examinés par notre équipe de modération. Les signalements faux peuvent entraîner des restrictions de compte.",
        "ads_ad_report_text_report_submitted": "Signalement envoyé avec succès. Merci d'aider à maintenir notre communauté en sécurité.",
        "ads_ad_report_text_failed_to_submit": "Échec de l'envoi du signalement",
        "ads_ad_report_text_report": "Signalement",
        "ads_ad_small_banner_text_learn": "En savoir",
        "ads_ad_badge_text_featured": "En vedette",
    },
    "de": {
        "ads_ad_migration_text_dry_run_results": "Simulationsergebnisse",
        "ads_ad_migration_text_migration_results": "Migrationsergebnisse",
        "ads_ad_migration_text_migration_statistics": "Migrationsstatistiken",
        "ads_ad_migration_text_old_collection": "Alte Sammlung",
        "ads_ad_migration_text_new_collection": "Neue Sammlung",
        "ads_ad_migration_text_remaining_to_migrate": "Verbleibend zu migrieren",
        "ads_ad_migration_text_about_migration": "Über die Migration",
        "ads_ad_migration_text_migration_description": "Dieses Tool migriert Anzeigen aus der alten \"ads\" Sammlung in die neue \"localAds\" Sammlung mit korrekter Feldzuordnung:\n\n• Konvertiert AdLocation/AdZone zu LocalAdZone\n• Ordnet AdStatus zu LocalAdStatus\n• Fügt neue Reporting-Felder hinzu (reportCount = 0)\n• Bewahrt alle Anzeigeninhalte und Metadaten\n• Überspringt bereits vorhandene Anzeigen (sofern Überschreiben nicht aktiviert ist)",
        "ads_ad_migration_text_migration_actions": "Migrationsaktionen",
        "ads_ad_migration_text_last_migration_result": "Letztes Migrationsergebnis",
        "ads_ad_migration_text_total_found": "Gesamt gefunden",
        "ads_ad_migration_text_migrated": "Migriert",
        "ads_ad_migration_text_skipped": "Übersprungen",
        "ads_ad_migration_text_failed": "Fehlgeschlagen",
        "ads_ad_migration_text_errors": "Fehler",
        "ads_ad_migration_text_more_errors": "... und {count} weitere",
        "ads_ad_migration_text_overwrite_warning": "Dies wird EXISTIERENDE Anzeigen in der localAds-Sammlung ÜBERSCHREIBEN, die dieselbe ID wie Anzeigen in der alten Sammlung haben.\n\nDiese Aktion kann nicht rückgängig gemacht werden. Sind Sie sicher, dass Sie fortfahren möchten?",
        "ads_ad_migration_text_overwrite": "Überschreiben",
        "ads_create_local_ad_text_promote_your_art": "Bewerben Sie Ihre Kunst",
        "ads_create_local_ad_text_reach_art_lovers": "Erreichen Sie Kunstliebhaber in stark frequentierten Bereichen",
        "ads_create_local_ad_text_ad_content": "Anzeigeninhalt",
        "ads_create_local_ad_text_image_optional": "Bild (optional)",
        "ads_create_local_ad_text_tap_to_select_image": "Tippen, um ein Bild auszuwählen",
        "ads_create_local_ad_text_where_to_display": "Wo anzeigen",
        "ads_create_local_ad_text_select_zone": "Zone auswählen",
        "ads_create_local_ad_text_size_and_duration": "Größe & Dauer",
        "ads_create_local_ad_text_select_size": "Größe auswählen",
        "ads_create_local_ad_text_select_duration": "Dauer auswählen",
        "ads_create_local_ad_text_post_ad_for_price": "Anzeige posten für ${price}",
        "ads_local_ads_list_text_no_ads_in_zone": "Keine Anzeigen in {zone}",
        "ads_local_ads_list_text_be_first_to_post": "Seien Sie der Erste, der etwas postet!",
        "ads_my_ads_text_no_ads_yet": "Noch keine Anzeigen",
        "ads_my_ads_text_post_first_ad": "Posten Sie Ihre erste Anzeige, um zu beginnen",
        "ads_my_ads_text_active_ads": "Aktive Anzeigen ({count})",
        "ads_my_ads_text_expired_ads": "Abgelaufene Anzeigen ({count})",
        "ads_my_ads_text_delete": "Löschen",
        "ads_ad_card_text_delete": "Löschen",
        "ads_ad_carousel_text_ad": "Anzeige",
        "ads_ad_cta_text_learn_more": "Mehr erfahren",
        "ads_ad_grid_text_ad": "Anzeige",
        "ads_ad_native_text_sponsored": "Gesponsert",
        "ads_ad_report_text_report_advertisement": "Anzeige melden",
        "ads_ad_report_text_ad_prefix": "Anzeige:",
        "ads_ad_report_text_whats_wrong": "Was stimmt nicht mit dieser Anzeige?",
        "ads_ad_report_text_cancel": "Abbrechen",
        "ads_ad_report_text_submit_report": "Bericht absenden",
        "ads_ad_report_text_disclaimer": "Berichte werden von unserem Moderationsteam geprüft. Falsche Berichte können zu Kontobeschränkungen führen.",
        "ads_ad_report_text_report_submitted": "Bericht erfolgreich eingereicht. Danke, dass Sie helfen, unsere Community sicher zu halten.",
        "ads_ad_report_text_failed_to_submit": "Fehler beim Senden des Berichts",
        "ads_ad_report_text_report": "Bericht",
        "ads_ad_small_banner_text_learn": "Erfahren",
        "ads_ad_badge_text_featured": "Hervorgehoben",
    },
    "pt": {
        "ads_ad_migration_text_dry_run_results": "Resultados do teste",
        "ads_ad_migration_text_migration_results": "Resultados da migração",
        "ads_ad_migration_text_migration_statistics": "Estatísticas de migração",
        "ads_ad_migration_text_old_collection": "Coleção antiga",
        "ads_ad_migration_text_new_collection": "Nova coleção",
        "ads_ad_migration_text_remaining_to_migrate": "Restantes para migrar",
        "ads_ad_migration_text_about_migration": "Sobre a migração",
        "ads_ad_migration_text_migration_description": "Esta ferramenta migra anúncios da coleção antiga \"ads\" para a nova coleção \"localAds\" com o mapeamento correto de campos:\n\n• Converte AdLocation/AdZone para LocalAdZone\n• Mapeia AdStatus para LocalAdStatus\n• Adiciona novos campos de relatório (reportCount = 0)\n• Preserva todo o conteúdo e metadados dos anúncios\n• Ignora anúncios já existentes (a menos que a substituição esteja ativada)",
        "ads_ad_migration_text_migration_actions": "Ações de migração",
        "ads_ad_migration_text_last_migration_result": "Último resultado da migração",
        "ads_ad_migration_text_total_found": "Total encontrados",
        "ads_ad_migration_text_migrated": "Migrados",
        "ads_ad_migration_text_skipped": "Ignorados",
        "ads_ad_migration_text_failed": "Falhou",
        "ads_ad_migration_text_errors": "Erros",
        "ads_ad_migration_text_more_errors": "... e {count} mais",
        "ads_ad_migration_text_overwrite_warning": "Isto irá SOBRESCREVER quaisquer anúncios existentes na coleção localAds que tenham o mesmo ID que os anúncios na coleção antiga.\n\nEsta ação não pode ser desfeita. Tem certeza de que deseja continuar?",
        "ads_ad_migration_text_overwrite": "Sobrescrever",
        "ads_create_local_ad_text_promote_your_art": "Promova sua arte",
        "ads_create_local_ad_text_reach_art_lovers": "Alcance amantes da arte em áreas de grande movimento",
        "ads_create_local_ad_text_ad_content": "Conteúdo do anúncio",
        "ads_create_local_ad_text_image_optional": "Imagem (Opcional)",
        "ads_create_local_ad_text_tap_to_select_image": "Toque para selecionar imagem",
        "ads_create_local_ad_text_where_to_display": "Onde exibir",
        "ads_create_local_ad_text_select_zone": "Selecionar zona",
        "ads_create_local_ad_text_size_and_duration": "Tamanho e duração",
        "ads_create_local_ad_text_select_size": "Selecionar tamanho",
        "ads_create_local_ad_text_select_duration": "Selecionar duração",
        "ads_create_local_ad_text_post_ad_for_price": "Publicar anúncio por ${price}",
        "ads_local_ads_list_text_no_ads_in_zone": "Sem anúncios em {zone}",
        "ads_local_ads_list_text_be_first_to_post": "Seja o primeiro a publicar!",
        "ads_my_ads_text_no_ads_yet": "Ainda sem anúncios",
        "ads_my_ads_text_post_first_ad": "Publique seu primeiro anúncio para começar",
        "ads_my_ads_text_active_ads": "Anúncios ativos ({count})",
        "ads_my_ads_text_expired_ads": "Anúncios expirados ({count})",
        "ads_my_ads_text_delete": "Excluir",
        "ads_ad_card_text_delete": "Excluir",
        "ads_ad_carousel_text_ad": "Anúncio",
        "ads_ad_cta_text_learn_more": "Saiba mais",
        "ads_ad_grid_text_ad": "Anúncio",
        "ads_ad_native_text_sponsored": "Patrocinado",
        "ads_ad_report_text_report_advertisement": "Denunciar anúncio",
        "ads_ad_report_text_ad_prefix": "Anúncio:",
        "ads_ad_report_text_whats_wrong": "O que há de errado com este anúncio?",
        "ads_ad_report_text_cancel": "Cancelar",
        "ads_ad_report_text_submit_report": "Enviar denúncia",
        "ads_ad_report_text_disclaimer": "As denúncias são analisadas pela nossa equipe de moderação. Denúncias falsas podem resultar em restrições de conta.",
        "ads_ad_report_text_report_submitted": "Denúncia enviada com sucesso. Obrigado por ajudar a manter nossa comunidade segura.",
        "ads_ad_report_text_failed_to_submit": "Falha ao enviar a denúncia",
        "ads_ad_report_text_report": "Denúncia",
        "ads_ad_small_banner_text_learn": "Saiba",
        "ads_ad_badge_text_featured": "Em destaque",
    },
    "zh": {
        "ads_ad_migration_text_dry_run_results": "模拟运行结果",
        "ads_ad_migration_text_migration_results": "迁移结果",
        "ads_ad_migration_text_migration_statistics": "迁移统计",
        "ads_ad_migration_text_old_collection": "旧集合",
        "ads_ad_migration_text_new_collection": "新集合",
        "ads_ad_migration_text_remaining_to_migrate": "剩余待迁移",
        "ads_ad_migration_text_about_migration": "关于迁移",
        "ads_ad_migration_text_migration_description": "此工具将旧的 \"ads\" 集合中的广告迁移到新的 \"localAds\" 集合，正确映射字段：\n\n• 将 AdLocation/AdZone 转换为 LocalAdZone\n• 将 AdStatus 映射为 LocalAdStatus\n• 添加新的上报字段（reportCount = 0）\n• 保留所有广告内容和元数据\n• 跳过已存在的广告（除非启用了覆盖）",
        "ads_ad_migration_text_migration_actions": "迁移操作",
        "ads_ad_migration_text_last_migration_result": "上次迁移结果",
        "ads_ad_migration_text_total_found": "总数",
        "ads_ad_migration_text_migrated": "已迁移",
        "ads_ad_migration_text_skipped": "已跳过",
        "ads_ad_migration_text_failed": "失败",
        "ads_ad_migration_text_errors": "错误",
        "ads_ad_migration_text_more_errors": "... 以及另外 {count} 条",
        "ads_ad_migration_text_overwrite_warning": "此操作将覆盖 localAds 集合中与旧集合中广告 ID 相同的现有广告。\n\n此操作不可撤销。确定要继续吗？",
        "ads_ad_migration_text_overwrite": "覆盖",
        "ads_create_local_ad_text_promote_your_art": "推广你的艺术",
        "ads_create_local_ad_text_reach_art_lovers": "在高流量区域吸引艺术爱好者",
        "ads_create_local_ad_text_ad_content": "广告内容",
        "ads_create_local_ad_text_image_optional": "图片（可选）",
        "ads_create_local_ad_text_tap_to_select_image": "点击以选择图片",
        "ads_create_local_ad_text_where_to_display": "显示位置",
        "ads_create_local_ad_text_select_zone": "选择区域",
        "ads_create_local_ad_text_size_and_duration": "大小与时长",
        "ads_create_local_ad_text_select_size": "选择大小",
        "ads_create_local_ad_text_select_duration": "选择时长",
        "ads_create_local_ad_text_post_ad_for_price": "发布广告：${price}",
        "ads_local_ads_list_text_no_ads_in_zone": "{zone} 没有广告",
        "ads_local_ads_list_text_be_first_to_post": "成为第一个发布者！",
        "ads_my_ads_text_no_ads_yet": "尚无广告",
        "ads_my_ads_text_post_first_ad": "发布你的第一则广告开始",
        "ads_my_ads_text_active_ads": "活动广告 ({count})",
        "ads_my_ads_text_expired_ads": "过期广告 ({count})",
        "ads_my_ads_text_delete": "删除",
        "ads_ad_card_text_delete": "删除",
        "ads_ad_carousel_text_ad": "广告",
        "ads_ad_cta_text_learn_more": "了解更多",
        "ads_ad_grid_text_ad": "广告",
        "ads_ad_native_text_sponsored": "赞助",
        "ads_ad_report_text_report_advertisement": "举报广告",
        "ads_ad_report_text_ad_prefix": "广告：",
        "ads_ad_report_text_whats_wrong": "这则广告有什么问题？",
        "ads_ad_report_text_cancel": "取消",
        "ads_ad_report_text_submit_report": "提交举报",
        "ads_ad_report_text_disclaimer": "举报会由我们的审核团队处理。虚假举报可能导致账号受限。",
        "ads_ad_report_text_report_submitted": "举报提交成功。感谢你帮助维护社区安全。",
        "ads_ad_report_text_failed_to_submit": "提交举报失败",
        "ads_ad_report_text_report": "举报",
        "ads_ad_small_banner_text_learn": "了解",
        "ads_ad_badge_text_featured": "精选",
    },
}


def extract_placeholders(s: str):
    return set(PLACEHOLDER_REGEX.findall(s))


def merge_translations():
    en = json.loads(EN_FILE.read_text())
    summary = {lang: {"added": [], "updated": [], "errors": []} for lang in TARGET_LANGS}

    for lang in TARGET_LANGS:
        lang_file = TRANSLATIONS_DIR / f"{lang}.json"
        if not lang_file.exists():
            print(f"ERROR: target language file missing: {lang_file}")
            continue
        data = json.loads(lang_file.read_text())
        new_trans = TRANSLATIONS.get(lang, {})

        for key, en_val in en.items():
            if key not in new_trans:
                # If our translations dict doesn't have it, skip (shouldn't happen)
                continue
            translated = new_trans[key]

            # Validate placeholders
            en_ph = extract_placeholders(en_val)
            tr_ph = extract_placeholders(translated)
            if en_ph != tr_ph:
                summary[lang]["errors"].append({"key": key, "en_ph": list(en_ph), "tr_ph": list(tr_ph)})

            # Decide whether to write: if key missing or value starts with '[' placeholder, update
            existing = data.get(key)
            if existing is None or (isinstance(existing, str) and existing.strip().startswith("[")):
                data[key] = translated
                if existing is None:
                    summary[lang]["added"].append(key)
                else:
                    summary[lang]["updated"].append(key)

        # Backup and write
        backup = lang_file.with_suffix(lang_file.suffix + ".bak")
        backup.write_text(json.dumps(json.loads(lang_file.read_text()), ensure_ascii=False, indent=2))
        lang_file.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")

    return summary


def merge_into_en():
    """Merge keys from artbeat_ads_texts_data.json into assets/translations/en.json if missing."""
    en_data_source = json.loads(EN_FILE.read_text())
    en_lang_file = TRANSLATIONS_DIR / "en.json"
    if not en_lang_file.exists():
        print(f"ERROR: en.json missing: {en_lang_file}")
        return {"added": [], "updated": []}

    data = json.loads(en_lang_file.read_text())
    added = []
    updated = []
    for key, val in en_data_source.items():
        existing = data.get(key)
        if existing is None or (isinstance(existing, str) and existing.strip().startswith("[")):
            data[key] = val
            if existing is None:
                added.append(key)
            else:
                updated.append(key)

    # Write backup and new file
    backup = en_lang_file.with_suffix(en_lang_file.suffix + ".bak")
    backup.write_text(json.dumps(json.loads(en_lang_file.read_text()), ensure_ascii=False, indent=2))
    en_lang_file.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    return {"added": added, "updated": updated}


if __name__ == "__main__":
    print("Merging artbeat_ads translations into assets/translations...")
    result = merge_translations()
    print(json.dumps(result, ensure_ascii=False, indent=2))
    print("\nMerging english keys into assets/translations/en.json...")
    en_merge = merge_into_en()
    print(json.dumps(en_merge, ensure_ascii=False, indent=2))