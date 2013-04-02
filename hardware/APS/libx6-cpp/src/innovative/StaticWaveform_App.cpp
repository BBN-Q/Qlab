// StaticWaveform_App.cpp
//
//    INNOVATIVE INTEGRATION CORPORATION PROPRIETARY INFORMATION
//  This software is supplied under the terms of a license agreement or nondisclosure
//  agreement with Innovative Integration Corporation and may not be copied or
//  disclosed except in accordance with the terms of that agreement.
//  Copyright (c) 2000..2007 Innovative Integration Corporation.
//  All Rights Reserved.
//

#include <Application/StaticWaveform_App.h>
#include <SystemSupport_Mb.h>
#include <Magic_Mb.h>
#include <StopWatch_Mb.h>
#include <iostream>
#include <sstream>
#include <fstream>
#include <limits>
#include <DataLogger_Mb.h>
#include <DataPlayer_Mb.h>
#include <IppCharDG_Mb.h>

using namespace std;

namespace Innovative
{

//=============================================================================
//  CLASS StaticWaveform  --  Endpoint-disciplined waveform generator
//=============================================================================

//------------------------------------------------------------------------
//  Ctor --
//------------------------------------------------------------------------

StaticWaveform::StaticWaveform()
    : FSamples(1000), FSampleRate(1.0e6), FFrequency(1.0e3),
      FAmplitude(95.0), FOffset(0), FPhase(0.), FBits(16),
      FChannels(1), FType(wtSine)
{
}

//------------------------------------------------------------------------
// StaticWaveform::Format()
//------------------------------------------------------------------------

void StaticWaveform::Format(int channels, int bits, int samples)
{

    FSamples = samples;
    FChannels = channels;
    FBits = bits;

    DoubleDG Waveform(Data);

    cout << "StaticWaveform::Format samples = " << FSamples << " FChannels " << FChannels << " packet size = " << FSamples*FChannels << endl;

    Waveform.Resize(FSamples*FChannels);
    Zero();
}

//------------------------------------------------------------------------
// StaticWaveform::Resize()
//------------------------------------------------------------------------

void StaticWaveform::Resize(Buffer & data)
{
    if (FBits <= 8)
        data.Resize(Holding<char>(FSamples*FChannels));
    else if (FBits <= 16)
        data.Resize(Holding<short>(FSamples*FChannels));
    else
        data.Resize(Holding<int>(FSamples*FChannels));
}

//------------------------------------------------------------------------
// StaticWaveform::Zero()
//------------------------------------------------------------------------

void StaticWaveform::Zero(int ch)
{
    DoubleDG Waveform(Data);

    for (unsigned int n = 0; n < FSamples; ++n)
        Waveform[n*FChannels+ch] = 0.;
}

//------------------------------------------------------------------------
// StaticWaveform::Zero()
//------------------------------------------------------------------------

void StaticWaveform::Zero()
{
    for (unsigned int ch = 0; ch < FChannels; ++ch)
        Zero(ch);
}

//------------------------------------------------------------------------
// StaticWaveform::Apply() -- Copy data out to buffer
//------------------------------------------------------------------------

void StaticWaveform::Apply(Buffer & data)
{
    cout << "StaticWaveform::Apply" << endl;
    for (unsigned int ch = 0; ch < FChannels; ++ch)
        {
        Copy(data, ch);
        }
}

//------------------------------------------------------------------------
// StaticWaveform::Accumulate()
//------------------------------------------------------------------------

bool StaticWaveform::Accumulate(int ch)
{

    cout << "StaticWaveform::Accumulate" << endl;
    DoubleDG Waveform(Data);
    if (!Waveform.SizeInElements())
        {
        ProcessStatusEvent e("Error: Format or Resize prior to Accumulate");
        OnMessage.Execute(e);
        return false;
        }

    // Recalculate the wave frequency.
    double wrf = FSampleRate / static_cast<double>(FSamples);
    FFrequencyActual = wrf * floor(FFrequency / wrf);

	double Ts = 1.0 / FSampleRate;
	double Pi = 4.0*std::atan(1.0);
	double TwoPi = 2.0 * Pi;
    double phase = FPhase * Pi / 180.0;

	// Amplitude.
	double FScale = (1 << (FBits-1))-1;
	double A = FScale * FAmplitude/100.0;
	double O = FScale * FOffset/100.0;

    std::stringstream cio;
    const char * wavetypes[] = { "Triangle", "Sine", "Square", "Ramp", "File" };
    cio << "Wave type: "          << wavetypes[FType];
    cio << ", Actual freq: "      << FFrequencyActual;
    cio << ", WRF: "              << wrf;
    cio << ", Samples/buffer: "   << FSamples;
    cio << ", BufferSize: "       << Waveform.SizeInBytes();
    cio << ", Bits: "             << FBits;
    cio << ", Channels: "         << FChannels;
    cio << ", Channel: "          << ch;

    ProcessStatusEvent e(cio.str());
    OnMessage.Execute(e);

    cout << "Accumulating Waveform FChannels = " << FChannels << " ch = " << ch << " offset = " << O << endl;

    FType = wtSquare;

    switch (FType)
        {
        // Triangle
        case wtTriangle:
            {
            const double Middle = Pi;
            const double Step = FFrequencyActual/FSampleRate*TwoPi;
            double Angle = Pi/2.0 + phase;

            for (size_t n = 0; n < FSamples; ++n)
                {
                double Scale;
                if ((Angle < Middle))
                    Scale = Angle / Middle;
                else
                    Scale = (TwoPi-Angle) / (TwoPi-Middle);

                Angle += Step;
                if (Angle >= TwoPi)
                    Angle -= TwoPi;

                // Populate buffer.
                double sample = (2.0*A * Scale) - A;
                Waveform[n*FChannels+ch] += sample + O;
                }
            }
            break;
        // Sine
        case wtSine:
            // Populate buffer.
            for (unsigned int n = 0; n < FSamples; ++n)
                {
                double sample = A * sin((TwoPi * Ts * n * FFrequencyActual) + phase);
                Waveform[n*FChannels+ch] += sample + O;
                }
            break;
        // Square
        case wtSquare:
            // Populate buffer.
            for (unsigned int n = 0; n < FSamples; ++n)
                {
                double sample = A * sin((TwoPi * Ts * n * FFrequencyActual) + phase + Pi/2.0);
                Waveform[n*FChannels+ch] += ((sample >= 0) ? A : -A) + O;
                }
            break;
        // Ramp
        case wtRamp:
            for (unsigned int n = 0; n < FSamples; ++n)
                {
                double Up = fmod(n, 2*A) - A;
                double Down = A-1-n;
                double Sample = ch ? Down : Up;
                Waveform[n*FChannels+ch] += Sample + O;
                }
            break;
	case wtFile:
	default:
		break;
        }

    //Normalize(ch);

    return true;
}

//------------------------------------------------------------------------
// StaticWaveform::Accumulate()
//------------------------------------------------------------------------

bool StaticWaveform::Accumulate()
{
    bool result = true;
    for (unsigned int ch = 0; ch < FChannels; ++ch)
        result &= Accumulate(ch);

    return result;
}

//------------------------------------------------------------------------
// StaticWaveform::Copy()
//------------------------------------------------------------------------

void StaticWaveform::Copy(Buffer & data, int ch)
{
    DoubleDG Waveform(Data);
    // Samples per buffer.

    if (FBits <= 8)
        {
        CharDG dg(data);
        // Populate buffer.
        for (unsigned int n = 0; n < FSamples; ++n)
            {
            int idx = n*FChannels+ch;
            dg[idx] = static_cast<char>(Waveform[idx]);
            }
        }
    else if (FBits <= 16)
        {
        ShortDG dg(data);
        // Populate buffer.
        for (unsigned int n = 0; n < FSamples; ++n)
            {
            int idx = n*FChannels+ch;
            dg[idx] = static_cast<short>(Waveform[idx]);
            cout << dg[idx]  << " " << Waveform[idx] << endl;
            }
        }
    else
        {
        IntegerDG dg(data);
        // Populate buffer.
        for (unsigned int n = 0; n < FSamples; ++n)
            {
            int idx = n*FChannels+ch;
            dg[idx] = static_cast<int>(Waveform[idx]);
            }
        }
}

//------------------------------------------------------------------------
// StaticWaveform::Normalize()
//------------------------------------------------------------------------

bool StaticWaveform::Normalize(int ch)
{
    DoubleDG Waveform(Data);

    // Add waveform elements
    double maximum = std::numeric_limits<double>::min();
    for (unsigned int n = 0; n < FSamples; ++n)
        {
        int idx = n*FChannels+ch;
        maximum = std::max(Waveform[idx], maximum);
        }

    // Normalize
    double A = ((1 << (FBits-1))-1) * FAmplitude/100.0;
    double scale = A/maximum;
    for (unsigned int n = 0; n < FSamples; ++n)
        {
        int idx = n*FChannels+ch;
        Waveform[idx] *= scale;
        }

    return true;
}

//=============================================================================
//  CLASS WaveformFile  --  Waveform file I/O
//=============================================================================
//------------------------------------------------------------------------------
//  constructor for class WaveformFile -- default ctor
//------------------------------------------------------------------------------

WaveformFile::WaveformFile()
    : FSamples(1000), FSampleRate(1.0e6), FBits(16),
      FChannels(1)
{

}

//------------------------------------------------------------------------
// WaveformFile::Save()
//------------------------------------------------------------------------

void WaveformFile::Save(const std::string & filename, const Buffer & buffer)
{
    std::ofstream file;
    file.open(filename.c_str(), std::ios::binary);
    file.write(reinterpret_cast<const char*>(buffer.ConstData()), buffer.SizeInBytes());
    file.close();

    Bv.BinFile(filename);

    // Make a new BDD
    const int bits = FBits;
    const int limit = 1 << (bits-1);

    Bv.Time().LowerLimit(-limit);
    Bv.Time().UpperLimit(limit);
    Bv.Time().Break(1);
    Bv.Time().AnnotateSeams(false);
    Bv.Fft().LowerLimit(-150);
    Bv.Fft().ScaleYType(BinViewOptions::FftOptions::sLog);
    Bv.Fft().ScaleXType(BinViewOptions::FftOptions::sLog);
    Bv.Fft().CriteriaThreshold(75);
    int pktsize = std::min(FSamples, 0x10000u);
    int tzc = TrailingZeroCount(NextSmallestPowerOfTwo(pktsize));
    BinViewOptions::FftOptions::IIPoints pts(static_cast<BinViewOptions::FftOptions::IIPoints>(tzc-7));
    Bv.Fft().Points(pts);
    Bv.Fft().Window(BinViewOptions::FftOptions::wBlackmann);
    Bv.Fft().Average(1);
    Bv.Text().DataFormat("%11.3f");
    Bv.System().UpdateRate(BinViewOptions::SystemOptions::ms1000);
    Bv.System().ServerSlotName("StaticWaveform");
    Bv.SignificantBits(bits);
    Bv.Polarity(FUnipolar ? BinView::pUnsigned : BinView::pSigned);
    Bv.DataSpan(300);
    Bv.DataType(BinView::tInt);
    Bv.Units("mV");
    Bv.Samples(1000);
    Bv.Channels(FChannels);
    Bv.Devices(1);
    Bv.System().Source(BinViewOptions::SystemOptions::sFile);
    Bv.NullDataValue(.12345e-19f);
    float rate = static_cast<float>(FSampleRate/1000.);
    Bv.SampleRate(rate);
    Bv.ScalingEnabled(true);

    Bv.Save();
}

//------------------------------------------------------------------------
//  WaveformFile::Load() -- Load waveform into buffer from file
//------------------------------------------------------------------------

void WaveformFile::Load(const std::string & filename, Buffer & buffer)
{
    Bv.BinFile(filename);
    Bv.Restore();

    CharDG DG(buffer);

    std::ifstream file;
    file.open(filename.c_str(), std::ios::binary | std::ios::ate);
    DG.Resize(static_cast<size_t>(file.tellg()));
    file.seekg (0, ios::beg);   // Rewind to beginning of file
    file.read(&DG[0], DG.SizeInElements());
    file.close();
}

//------------------------------------------------------------------------
//  WaveformFile::Load_noResize() -- Load waveform into buffer from file
//------------------------------------------------------------------------

void WaveformFile::Load_noResize(const std::string & filename, Buffer & buffer)
{
    Bv.BinFile(filename);
    Bv.Restore();

    IppCharDG DG(buffer);

    std::ifstream file;
    file.open(filename.c_str(), std::ios::binary | std::ios::ate);
    size_t file_size =  static_cast<size_t>(file.tellg());
    size_t transfer_size = std::min(file_size, DG.SizeInElements());
    if (transfer_size != DG.SizeInElements())
        {
        //  file smaller than buffer, so zero buffer first
        DG.Zero();
        }

    // read data from file
    file.seekg (0, ios::beg);   // Rewind to beginning of file
    file.read(&DG[0], transfer_size);
    file.close();
}

//---------------------------------------------------------------------------
//  WaveformFile::Show() --  Set up BDD File for an output file
//---------------------------------------------------------------------------

void WaveformFile::Show()
{
    Bv.Plot();
}

//---------------------------------------------------------------------------
//  WaveformFile::Hide() --  Set up BDD File for an output file
//---------------------------------------------------------------------------

void WaveformFile::Hide()
{
    Bv.Quit();
}

//=============================================================================
//  CLASS VitaWaveformFile  --  Waveform file I/O
//=============================================================================
//------------------------------------------------------------------------------
//  constructor for class VitaWaveformFile -- default ctor
//------------------------------------------------------------------------------

VitaWaveformFile::VitaWaveformFile()
    : FDevices(1), FSamples(1000), FSampleRate(1.0e6), FBits(16),
      FChannels(1)
{

}

//------------------------------------------------------------------------
// VitaWaveformFile::Save()
//------------------------------------------------------------------------

void VitaWaveformFile::Save(const std::string & filename, const VeloBuffer & buffer)
{
    DataLogger Logger;
    Logger.FileName(filename);
    Logger.Start();
    Logger.LogWithHeader(buffer);
    Logger.Stop();

    Bv.BinFile(filename);

    // Make a new BDD
    const int bits = FBits;
    const int limit = 1 << (bits-1);

    Bv.Time().LowerLimit(-limit);
    Bv.Time().UpperLimit(limit);
    Bv.Time().Break(1);
    Bv.Time().AnnotateSeams(false);
    Bv.Fft().LowerLimit(-150);
    Bv.Fft().ScaleYType(BinViewOptions::FftOptions::sLog);
    Bv.Fft().ScaleXType(BinViewOptions::FftOptions::sLog);
    Bv.Fft().CriteriaThreshold(75);
    int pktsize = std::min(FSamples, 0x10000u);
    int tzc = TrailingZeroCount(NextSmallestPowerOfTwo(pktsize));
    BinViewOptions::FftOptions::IIPoints pts(static_cast<BinViewOptions::FftOptions::IIPoints>(tzc-7));
    Bv.Fft().Points(pts);
    Bv.Fft().Window(BinViewOptions::FftOptions::wBlackmann);
    Bv.Fft().Average(1);
    Bv.Text().DataFormat("%11.3f");
    Bv.System().UpdateRate(BinViewOptions::SystemOptions::ms1000);
    Bv.System().ServerSlotName("VeloStaticWaveform");
    Bv.SignificantBits(bits);
    Bv.Polarity(FUnipolar ? BinView::pUnsigned : BinView::pSigned);
    Bv.DataSpan(300);
    Bv.DataType(BinView::tInt);
    Bv.Units("mV");
    Bv.Samples(1000);
    Bv.Channels(FChannels);
    Bv.Devices(FDevices);
    Bv.System().Source(BinViewOptions::SystemOptions::sVita);
    Bv.NullDataValue(.12345e-19f);
    float rate = static_cast<float>(FSampleRate/1000.);
    Bv.SampleRate(rate);
    Bv.ScalingEnabled(true);

    Bv.Save();
}

//------------------------------------------------------------------------
//  VitaWaveformFile::Load() -- Load waveform into buffer from file
//------------------------------------------------------------------------

void VitaWaveformFile::Load(const std::string & filename, VeloBuffer & buffer)
{
    Bv.BinFile(filename);
    Bv.Restore();

    CharDG DG(buffer);

    DataPlayer Player;
    Player.FileName(filename);
    Player.Start();
    Player.PlayWithHeader(buffer);
    Player.Stop();
}

//---------------------------------------------------------------------------
//  VitaWaveformFile::Show() --  Set up BDD File for an output file
//---------------------------------------------------------------------------

void VitaWaveformFile::Show()
{
    Bv.Plot();
}

//---------------------------------------------------------------------------
//  VitaWaveformFile::Hide() --  Set up BDD File for an output file
//---------------------------------------------------------------------------

void VitaWaveformFile::Hide()
{
    Bv.Quit();
}

//==============================================================================
//  CLASS DualWaveGenerator
//==============================================================================
//---------------------------------------------------------------------------
//  DualWaveGenerator::SingleWave() -- Calculate single wave channel
//---------------------------------------------------------------------------

bool  DualWaveGenerator::SingleWave(Buffer & data, int ch)
{
    cout << "DualWaveGenerator::SingleWave" << endl;
    Gen.Zero(ch);
    Gen.Amplitude( FAmplitude );
    bool rtn = Gen.Accumulate(ch);
    if (rtn)
        Gen.Apply(data);
    return rtn;
}

//---------------------------------------------------------------------------
//  DualWaveGenerator::SingleWave() -- Calculate single wave channel
//---------------------------------------------------------------------------

bool  DualWaveGenerator::SingleWave(Buffer & data)
{
    cout << "DualWaveGenerator::SingleWave(Buffer)" << endl;
    Gen.Zero();
    Gen.Amplitude( FAmplitude  );
    bool rtn = Gen.Accumulate();
    if (rtn)
        Gen.Apply(data);
    return rtn;
}

//---------------------------------------------------------------------------
//  DualWaveGenerator::DualWave() -- Calculate dual wave channel
//---------------------------------------------------------------------------

bool  DualWaveGenerator::DualWave(Buffer & data, int ch)
{
    double PrimaryFrequency = Gen.Frequency();

    Gen.Zero(ch);
    Gen.Amplitude( FAmplitude * .55 );

    bool rtn = Gen.Accumulate(ch);

    Gen.Amplitude( FAmplitude * .45 );
    Gen.Frequency( FSecondaryFrequency );
    rtn &= Gen.Accumulate(ch);

    Gen.Frequency( PrimaryFrequency );
    if (rtn)
        Gen.Apply(data);
    return rtn;
}

//---------------------------------------------------------------------------
//  DualWaveGenerator::DualWave() -- Calculate dual wave channel
//---------------------------------------------------------------------------

bool  DualWaveGenerator::DualWave(Buffer & data)
{
    double PrimaryFrequency = Gen.Frequency();

    Gen.Zero();
    Gen.Amplitude( FAmplitude * .55 );

    bool rtn = Gen.Accumulate();

    Gen.Amplitude( FAmplitude * .45 );
    Gen.Frequency( FSecondaryFrequency );
    rtn = Gen.Accumulate() && rtn;

    Gen.Frequency( PrimaryFrequency );
    if (rtn)
        Gen.Apply(data);
    return rtn;
}

//==============================================================================
//  CLASS WaveBuilder -- Class to manage Wave Building Setup
//==============================================================================
//------------------------------------------------------------------------------
//  WaveBuilder::BuildWave() -- Fill Buffer(s) with a waveform
//------------------------------------------------------------------------------

void WaveBuilder::BuildWave(Buffer & Buffer)
{
    StaticWaveform::IIType WF_Type =
                         static_cast<StaticWaveform::IIType>(Settings.WaveType);
    //
    //  set up generator parameters
    WaveGen.Gen.Frequency(Settings.WaveformFrequency * 1.e6);
    WaveGen.Gen.SampleRate(FSampleRate);
    WaveGen.Gen.Type(WF_Type);
    WaveGen.Amplitude(Settings.WaveformAmplitude);

    WaveGen.Gen.Format(FChannels, FBits, FSamples);

    //  Secondary frequency
    WaveGen.SecondaryFrequency(Settings.TwoToneFrequency * 1e6);

    if (WF_Type == StaticWaveform::wtFile)
        {
        WaveformFile WFF;
        WFF.Load(Settings.WaveFile, Buffer);
        }
    else
        {
        bool TwoToneMode       = Settings.TwoToneMode;
        bool SingleChannelMode = Settings.SingleChannelMode;

        if (!SingleChannelMode && !TwoToneMode)
            WaveGen.SingleWave(Buffer);   //  One Wave on all channels
        else if (!SingleChannelMode && TwoToneMode)
            WaveGen.DualWave(Buffer);     //  Sum of 2 Waves on all channels
        else if (SingleChannelMode && !TwoToneMode)
            {
            //  One Wave on one channel (others 0)
            WaveGen.Gen.Zero();
            WaveGen.SingleWave(Buffer, Settings.SingleChannelChannel);
            }
        else if (SingleChannelMode && TwoToneMode)
            {
            //  Sum of 2 waves on one channel (others 0)
            WaveGen.Gen.Zero();
            WaveGen.DualWave(Buffer, Settings.SingleChannelChannel);
            }
        else
            {
            // All Zero
            WaveGen.Gen.Zero();
            WaveGen.Gen.Apply(Buffer);
            }

        //  Test - dump to waveform file
        WaveformFile WFF;
        WFF.Format(FChannels, FBits, FSamples);
        WFF.SampleRate(FSampleRate);
        WFF.Save("WaveTestData.bin", Buffer);
        }

}

//------------------------------------------------------------------------------
//  WaveBuilder::ZeroWave() -- Fill with Zero Waveform
//------------------------------------------------------------------------------

void WaveBuilder::ZeroWave(Innovative::Buffer & Buffer)
{
    //
    //  set up generator parameters
    WaveGen.Gen.Format(FChannels, FBits, FSamples);
    //
    // All Zero
    WaveGen.Gen.Zero();
    WaveGen.Gen.Apply(Buffer);

}

//==============================================================================
//  CLASS VitaWaveBuilder -- Class to manage X6 Wave Building Setup
//==============================================================================
//------------------------------------------------------------------------------
//  VitaWaveBuilder::BuildWave() -- Fill Buffer(s) with a waveform
//------------------------------------------------------------------------------

void VitaWaveBuilder::BuildWave(VeloBuffer & Buffer)
{

    cout << "VitaWaveBuilder::BuildWave" << endl;
    StaticWaveform::IIType WF_Type =
                         static_cast<StaticWaveform::IIType>(Settings.WaveType);
    cout << "WF_Type = " << WF_Type;
    //  Fill scratch buffers
    CreateScratchBuffers();

    //  Fill scratch buffers
    if (WF_Type == StaticWaveform::wtFile)
        {
        LoadWaveFromFileList();
        }
    else
        {
        GenerateWave();
        }

    //  Create Output Playback Buffer
    FillOutputWaveBuffer(Buffer);
}

//------------------------------------------------------------------------------
//  VitaWaveBuilder::CreateScratchBuffers() --
//------------------------------------------------------------------------------

void  VitaWaveBuilder::CreateScratchBuffers()
{
    //  Each scratch buffer holds total_channels/total_devices channels
    size_t devices = FDeviceSids.size();
    size_t scratch_buffer_size = CalculateScratchBufferSize();

    Scratch.empty();
    Scratch.resize(devices);

    for (unsigned int i=0; i<Scratch.size(); i++)
        Scratch[i].Resize(scratch_buffer_size);
}

//------------------------------------------------------------------------------
//  VitaWaveBuilder::LoadWaveFromFileList() --
//------------------------------------------------------------------------------

void  VitaWaveBuilder::LoadWaveFromFileList()
{
    IniFile  Ini(Settings.WaveFile);

    size_t devices = FDeviceSids.size();
    std::vector<std::string>  DataFile;

    //  Read list of file names from INI file
    for (size_t i = 0; i < devices; i++)
        {
        std::string tag = "File" + IntToString((int)i);
        std::string file = Ini.Read(tag, std::string("dummyfile.dat"));
        DataFile.push_back(file);
        }

    for (size_t i = 0; i < devices; i++)
        {
        WaveformFile WFF;
        WFF.Load_noResize(DataFile[i], Scratch[i]);
        }
}

//------------------------------------------------------------------------------
//  VitaWaveBuilder::GenerateWave() --
//------------------------------------------------------------------------------

void  VitaWaveBuilder::GenerateWave()
{
    size_t devices = FDeviceSids.size();
    size_t channels = (devices) ? FChannels/devices : FChannels;
    StaticWaveform::IIType WF_Type =
                         static_cast<StaticWaveform::IIType>(Settings.WaveType);
    //
    //  set up generator parameters
    WaveGen.Gen.Frequency(Settings.WaveformFrequency * 1.e6);
    WaveGen.Gen.SampleRate(FSampleRate);
    WaveGen.Gen.Type(WF_Type);
    WaveGen.Amplitude(Settings.WaveformAmplitude);
    //  Secondary frequency
    WaveGen.SecondaryFrequency(Settings.TwoToneFrequency * 1e6);

    bool TwoToneMode       = Settings.TwoToneMode;
    bool SingleChannelMode = Settings.SingleChannelMode;
    size_t  SingleChannelDevice  = (devices) ? Settings.SingleChannelChannel/devices : 0 ;
    size_t  SingleChannelDevChan = (devices) ? Settings.SingleChannelChannel%devices : 0 ;

    cout << "TwoToneMode = " << TwoToneMode << " SingleChannelMode " << SingleChannelMode << endl;
    cout << "SingleChannelDevice = " << SingleChannelDevice << " SingleChannelDevChan " << SingleChannelDevChan << endl;

    for (size_t i=0; i<devices; i++)
        {
        cout << "WaveGen.Gen.Format" << endl;
        WaveGen.Gen.Format((int)channels, FBits, FSamples);

        if (!SingleChannelMode)
            {
            if (!TwoToneMode) {
                cout << "WaveGen.SingleWave" << endl;
                WaveGen.SingleWave(Scratch[i]);   //  One Wave on all channels
            } else { // TwoToneMode
                cout << "WaveGen.DualWave" << endl;
                WaveGen.DualWave(Scratch[i]);     //  Sum of 2 Waves on all channels
            }
        }
        else // SingleChannelMode
            {
            if ( i != (size_t)SingleChannelDevice )
                {
                // Single Channel not on device, so All Zero
                WaveGen.Gen.Zero();
                WaveGen.Gen.Apply(Scratch[i]);
                }
            else
                {
                if (!TwoToneMode)
                    {
                    //  One Wave on one channel (others 0)
                    WaveGen.Gen.Zero();
                    WaveGen.SingleWave(Scratch[i], (int)SingleChannelDevChan );
                    }
                else
                    {
                    //  Sum of 2 waves on one channel (others 0)
                    WaveGen.Gen.Zero();
                    WaveGen.DualWave(Scratch[i], (int)SingleChannelDevChan);
                    }
                }
            }
        }

}

//------------------------------------------------------------------------------
//  VitaWaveBuilder::FillOutputWaveBuffer() --
//------------------------------------------------------------------------------

void  VitaWaveBuilder::FillOutputWaveBuffer(VeloBuffer & OutputWaveform)
{
    cout << "VitaWaveBuilder::FillOutputWaveBuffer" << endl;
    //  We now have the data in an array of scratch buffers.
    //     We need to copy it into VITA packets, and then pack those VITAs
    //     into the outbound Waveform packet
    size_t words_remaining = Scratch[0].SizeInInts();
    //
    //  Use a packer to load full VITA packets into a velo packet
    //  ...Make the packer output size so big, we will not fill it before finishing
    VitaPacketPacker VPPk(words_remaining*Scratch.size()*2);
    VPPk.OnDataAvailable.SetEvent(this, &VitaWaveBuilder::HandlePackedDataAvailable);
    //
    //  Bust up the scratch buffer into VITA packets
    size_t offset = 0;
    size_t packet = 0;
    while (words_remaining)
        {
        //  calculate size of VITA packet
        size_t VP_size = min(MaxVitaSize(), words_remaining);

        //  Get a properly cleared/inited Vita Header
        VitaBuffer VBuf( VP_size );
        ClearHeader(VBuf);
        ClearTrailer(VBuf);
        InitHeader(VBuf);
        InitTrailer(VBuf);

        Innovative::UIntegerDG   VitaDG(VBuf);

        for (unsigned int stream=0; stream<Scratch.size(); stream++)
            {
                cout << "Stream " << stream << "sid = " << FDeviceSids[stream]  << endl;
            Innovative::UIntegerDG   ScratchDG(Scratch[stream]);

            //  Copy Data to Vita
            for (unsigned int idx=0; idx<VitaDG.size(); idx++) {
                VitaDG[idx] = ScratchDG[offset + idx];
                cout << VitaDG[idx] << " " <<  ScratchDG[offset + idx] << endl;
            }

            //  Init Vita Header
            VitaHeaderDatagram VitaH( VBuf );
            VitaH.StreamId( FDeviceSids[stream] );
            VitaH.PacketCount(static_cast<int>(packet));

            //  Shove in the new VITA packet
            VPPk.Pack( VBuf );
            }
        //  fix up buffer counters
        words_remaining -= VP_size;
        offset += VP_size;

        packet++;
        }

    VPPk.Flush();   // outputs the one waveform buffer into WaveformPacket

    ClearHeader(WaveformPacket);
    InitHeader(WaveformPacket);   // make sure header packet size is valid...

    // WaveformPacket is now correctly filled with data...

/*
    //  Test - dump to waveform file
    VitaWaveformFile WFF;
    WFF.Format((int)Scratch.size(), FChannels, FBits, FSamples);
    WFF.SampleRate(FSampleRate);
    WFF.Save("WaveTestData.bin", WaveformPacket);
*/
    OutputWaveform = WaveformPacket;   // "return" the waveform

}
//---------------------------------------------------------------------------
//  VitaWaveBuilder::HandlePackedDataAvailable() -- Packer Callback
//---------------------------------------------------------------------------

void  VitaWaveBuilder::HandlePackedDataAvailable(Innovative::VitaPacketPackerDataAvailable & event)
{
    WaveformPacket = event.Data;
}

//------------------------------------------------------------------------------
//  VitaWaveBuilder::CalculateScratchBufferSize() --
//------------------------------------------------------------------------------

size_t VitaWaveBuilder::CalculateScratchBufferSize()
{
    //  Each scratch buffer holds total_channels/total_devices channels
    size_t devices = FDeviceSids.size();
    size_t channels = (devices) ? FChannels/devices : FChannels;

    // calculate scratch packet size in ints
    size_t scratch_pkt_size;
    if (FBits <= 8)
        scratch_pkt_size = channels * Holding<char>(FSamples);
    else if (FBits <= 16)
        scratch_pkt_size = channels * Holding<short>(FSamples);
    else
        scratch_pkt_size = channels * FSamples;

    cout << "scratch_pkt_size = " << scratch_pkt_size << endl;

    return scratch_pkt_size;
}

} // namespace

