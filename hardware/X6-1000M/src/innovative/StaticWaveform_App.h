// StaticWaveform_App.h
//
//    INNOVATIVE INTEGRATION CORPORATION PROPRIETARY INFORMATION
//  This software is supplied under the terms of a license agreement or nondisclosure
//  agreement with Innovative Integration Corporation and may not be copied or
//  disclosed except in accordance with the terms of that agreement.
//  Copyright (c) 2000..2007 Innovative Integration Corporation.
//  All Rights Reserved.
//

#ifndef StaticWaveform_AppH
#define StaticWaveform_AppH

#include <ProcessEvents_Mb.h>
#include <Buffer_Mb.h>
#include <BufferDatagrams_Mb.h>
#include <BinView_Mb.h>
#include <VitaPacketStream_Mb.h>

namespace Innovative
{
#ifdef __CLR_VER
#pragma managed(push, off)
#endif

//==============================================================================
//  CLASS  WaveformFile
//==============================================================================

class WaveformFile
{
public:
    WaveformFile();


    void        SampleRate(double value)
        {  FSampleRate=value;  }
    double      SampleRate() const
        {  return FSampleRate;  }

    void        Format(int channels, int bits, int samples, bool unipolar=false)
                    {
                    FChannels = channels; FBits=bits;
                    FSamples=samples;  FUnipolar=unipolar;
                    }

    void        Load(const std::string & filename, Buffer & buffer);
    void        Save(const std::string & filename, const Buffer & buffer);
    void        Show();
    void        Hide();
    void        Load_noResize(const std::string & filename, Buffer & buffer);

private:
    unsigned int    FSamples;
    double          FSampleRate;
    unsigned int    FBits;
    unsigned int    FChannels;
    bool            FUnipolar;

    BinView         Bv;
};

//==============================================================================
//  CLASS  VitaWaveformFile
//==============================================================================

class VitaWaveformFile
{
public:
    VitaWaveformFile();


    void        SampleRate(double value)
        {  FSampleRate=value;  }
    double      SampleRate() const
        {  return FSampleRate;  }

    void        Format(int devices, int channels, int bits, int samples, bool unipolar=false)
                    {
                    FDevices = devices;
                    FChannels = channels; FBits=bits;
                    FSamples=samples;  FUnipolar=unipolar;
                    }

    void        Load(const std::string & filename, VeloBuffer & buffer);
    void        Save(const std::string & filename, const VeloBuffer & buffer);
    void        Show();
    void        Hide();

private:
    unsigned int    FDevices;
    unsigned int    FSamples;
    double          FSampleRate;
    unsigned int    FBits;
    unsigned int    FChannels;
    bool            FUnipolar;

    BinView         Bv;
};

//==============================================================================
//  CLASS  StaticWaveform
//==============================================================================

class StaticWaveform
{

public:
    enum IIType {wtTriangle, wtSine, wtSquare, wtRamp, wtFile };

    // Ctor
    StaticWaveform();

    // Methods
    void        Format(int channels, int bits, int samples);
    void        Resize(Buffer & data);

    void        Zero(int ch);
    void        Zero();

    bool        Accumulate(int ch);
    bool        Accumulate();
    
    void        Apply(Buffer & data);


    // Properties
    void        Type(IIType type)
        {  FType = type;  }
    IIType      Type() const
        {  return FType;  }

    void        SampleRate(double value)
        {  FSampleRate=value;  }
    double      SampleRate() const
        {  return FSampleRate;  }

    void        Frequency(double value)
        {  FFrequency=value;  }
    double      Frequency() const
        {  return FFrequency;  }
    double      FrequencyActual() const
        {  return FFrequencyActual;  }

    void        Amplitude(double percent)
        {  FAmplitude=percent;  }
    double      Amplitude() const
        {  return FAmplitude;  }

    void        Offset(double percent)
        {  FOffset=percent;  }
    double      Offset() const
        {  return FOffset;  }

    void        Phase(double value)
        {  FPhase=value;  }
    double      Phase() const
        {  return FPhase;  }

    OpenWire::ThunkedEventHandler<Innovative::ProcessStatusEvent> OnMessage;

protected:
    // Fields
    unsigned int    FSamples;
    double          FSampleRate;
    double          FFrequency;
    double          FFrequencyActual;
    double          FAmplitude;
    double          FOffset;
    double          FPhase;
    unsigned int    FBits;
    bool            FUnipolar;
    unsigned int    FChannels;
    IIType          FType;

    //BinView         Bv;
    Buffer          Data;

    bool Normalize(int ch);
    void Copy(Buffer & data, int ch);
};

//==============================================================================
//  CLASS DualWaveGenerator
//==============================================================================

class DualWaveGenerator
{
public:
    StaticWaveform   Gen;

    DualWaveGenerator()
        :  FAmplitude(.95)
        { }

    bool        SingleWave(Buffer & data, int ch);
    bool        SingleWave(Buffer & data);

    bool        DualWave(Buffer & data, int ch);
    bool        DualWave(Buffer & data);

    void        SecondaryFrequency(double value)
        {  FSecondaryFrequency = value;  }
    double      SecondaryFrequency() const
        {  return FSecondaryFrequency;  }
    void        Amplitude(double percent)
        {  FAmplitude=percent;  }
    double       Amplitude() const
        {  return FAmplitude;  }

private:
    double                       FAmplitude;
    double                       FSecondaryFrequency;


};

//==============================================================================
//  CLASS WaveBuilder -- Class to manage Wave Building Setup
//==============================================================================

class WaveBuilder
{
public:

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //  CLASS WaveBuilderSettings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    struct WaveBuilderSettings
    {
        std::string     WaveFile;
        int             WaveType;
        float           WaveformFrequency;
        float           WaveformAmplitude;
        bool            TwoToneMode;
        float           TwoToneFrequency;
        bool            SingleChannelMode;
        int             SingleChannelChannel;
    };

    WaveBuilderSettings  Settings;
    //
    //  Properties
    void        SampleRate(double value)
        {  FSampleRate=value;  }
    double      SampleRate() const
        {  return FSampleRate;  }

    void        Format(int channels, int bits, int samples)
                    {  FChannels = channels; FBits=bits; FSamples=samples;  }

    //
    //  Methods
    void  BuildWave(Buffer & Buffer);
    void  ZeroWave(Buffer & Buffer);

private:
    //
    //  Member Data
    unsigned int    FSamples;
    double          FSampleRate;
    unsigned int    FBits;
    unsigned int    FChannels;

    DualWaveGenerator   WaveGen;

};

//==============================================================================
//  CLASS VitaWaveBuilder -- Class to manage Wave Building for X6 Boards
//==============================================================================

class VitaWaveBuilder
{
public:

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //  CLASS VWB_Settings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    struct VWB_Settings
    {
        std::string     WaveFile;
        int             WaveType;
        float           WaveformFrequency;
        float           WaveformAmplitude;
        bool            TwoToneMode;
        float           TwoToneFrequency;
        bool            SingleChannelMode;
        int             SingleChannelChannel;
    };

    VWB_Settings  Settings;

    VitaWaveBuilder()
        :  FSampleRate(1e6), FMaxVitaSize(0xF000)
        {}
    //
    //  Properties
    void        SampleRate(double value)
        {  FSampleRate=value;  }
    double      SampleRate() const
        {  return FSampleRate;  }

    void    MaxVitaSize(size_t value)
                        {  FMaxVitaSize=value;  }
    size_t  MaxVitaSize() const
                        {  return FMaxVitaSize; }

    void        Format(const std::vector<int> & device_sids, int channels, int bits, int samples)
                    {
                    FDeviceSids = device_sids;  FChannels = channels;
                    FBits=bits; FSamples=samples;
                    }

    //
    //  Methods
    void  BuildWave(VeloBuffer & Buffer);

private:
    //
    //  Member Data
    unsigned int            FSamples;
    double                  FSampleRate;
    unsigned int            FBits;
    unsigned int            FChannels;
    std::vector<int>        FDeviceSids;
    size_t                  FMaxVitaSize;

    DualWaveGenerator    WaveGen;
    std::vector<Buffer>  Scratch;
    VeloBuffer           WaveformPacket;

    void    CreateScratchBuffers();
    void    LoadWaveFromFileList();
    void    GenerateWave();
    void    FillOutputWaveBuffer(VeloBuffer & OutputWaveform);

    size_t  CalculateScratchBufferSize();

    void    HandlePackedDataAvailable(VitaPacketPackerDataAvailable & event);

};


#ifdef __CLR_VER
#pragma managed(pop)
#endif
} // namespace Innovative

#endif

