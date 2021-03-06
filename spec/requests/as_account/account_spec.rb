# encoding: UTF-8
require 'spec_helper'
require 'yt/models/account'

describe Yt::Account, :device_app do
  describe 'can create playlists' do
    let(:params) { {title: 'Test Yt playlist', privacy_status: 'unlisted'} }
    before { @playlist = $account.create_playlist params }
    it { expect(@playlist).to be_a Yt::Playlist }
    after { @playlist.delete }
  end

  it { expect($account.channel).to be_a Yt::Channel }
  it { expect($account.playlists.first).to be_a Yt::Playlist }
  it { expect($account.subscribed_channels.first).to be_a Yt::Channel }
  it { expect($account.user_info).to be_a Yt::UserInfo }

  describe '.related_playlists' do
    let(:related_playlists) { $account.related_playlists }

    specify 'returns the list of associated playlist (Liked Videos, Uploads, ...)' do
      expect(related_playlists.first).to be_a Yt::Playlist
    end

    specify 'includes public related playlists (such as Liked Videos)' do
      uploads = related_playlists.select{|p| p.title.starts_with? 'Uploads'}
      expect(uploads).not_to be_empty
    end

    specify 'includes private playlists (such as Watch Later or History)' do
      watch_later = related_playlists.select{|p| p.title == 'Watch Later'}
      expect(watch_later).not_to be_empty

      history = related_playlists.select{|p| p.title == 'History'}
      expect(history).not_to be_empty
    end
  end

  describe '.videos' do
    let(:video) { $account.videos.where(order: 'viewCount').first }

    specify 'returns the videos uploaded by the account with their tags and category ID' do
      expect(video).to be_a Yt::Video
      expect(video.tags).not_to be_empty
      expect(video.category_id).not_to be_nil
    end

    describe '.where(q: query_string)' do
      let(:count) { $account.videos.where(q: query).count }

      context 'given a query string that matches any video owned by the account' do
        let(:query) { ENV['YT_TEST_MATCHING_QUERY_STRING'] }
        it { expect(count).to be > 0 }
      end

      context 'given a query string that does not match any video owned by the account' do
        let(:query) { '--not-a-matching-query-string--' }
        it { expect(count).to be_zero }
      end
    end

    describe 'ignores filters by ID (all the videos uploaded by the account are returned)' do
      let(:other_video) { $account.videos.where(order: 'viewCount', id: 'invalid').first }
      it { expect(other_video.id).to eq video.id }
    end

    describe 'ignores filters by chart (all the videos uploaded by the account are returned)' do
      let(:other_video) { $account.videos.where(order: 'viewCount', chart: 'invalid').first }
      it { expect(other_video.id).to eq video.id }
    end

    describe '.includes(:snippet)' do
      let(:video) { $account.videos.includes(:snippet).first }

      specify 'eager-loads the *full* snippet of each video' do
        expect(video.instance_variable_defined? :@snippet).to be true
        expect(video.channel_title).to be
        expect(video.snippet).to be_complete
      end
    end

    describe '.includes(:statistics, :status)' do
      let(:video) { $account.videos.includes(:statistics, :status).first }

      specify 'eager-loads the statistics and status of each video' do
        expect(video.instance_variable_defined? :@statistics_set).to be true
        expect(video.instance_variable_defined? :@status).to be true
      end
    end

    describe '.includes(:content_details)' do
      let(:video) { $account.videos.includes(:content_details).first }

      specify 'eager-loads the statistics of each video' do
        expect(video.instance_variable_defined? :@content_detail).to be true
      end
    end
  end

  describe '.video_groups' do
    let(:video_group) { $account.video_groups.first }

    specify 'returns the first video-group created by the account' do
      expect(video_group).to be_a Yt::VideoGroup
      expect(video_group.title).to be_a String
      expect(video_group.item_count).to be_an Integer
      expect(video_group.published_at).to be_a Time
    end

    specify 'allows to run reports against each video-group' do
      expect(video_group.views).to be
    end
  end

  describe '.upload_video' do
    let(:video_params) { {title: 'Test Yt upload', privacy_status: 'private', category_id: 17} }
    let(:video) { $account.upload_video path_or_url, video_params }
    after { video.delete }

    context 'given the path to a local video file' do
      let(:path_or_url) { File.expand_path '../video.mp4', __FILE__ }

      it { expect(video).to be_a Yt::Video }
    end

    context 'given the URL of a remote video file' do
      let(:path_or_url) { 'https://bit.ly/yt_test' }

      it { expect(video).to be_a Yt::Video }
    end
  end

  describe '.subscribers' do
    let(:subscriber) { $account.subscribers.first }

    specify 'returns the channels who are subscribed to me' do
      expect(subscriber).to be_a Yt::Channel
    end
  end
end